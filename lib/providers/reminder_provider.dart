import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:jiffy/jiffy.dart';

import '../model/task/reminder.dart';
import '../model/user/user.dart';
import '../services/notification_service.dart';
import '../services/reminder_service.dart';
import '../util/constants.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/sorting/reminder_sorter.dart';

class ReminderProvider extends ChangeNotifier {
  bool rebuild = false;
  late Timer syncTimer;

  final ReminderService _reminderService;

  // Singleton for now. DI later.
  final NotificationService _notificationService = NotificationService.instance;

  Reminder? curReminder;

  List<Reminder> reminders = [];

  late ReminderSorter sorter;

  User? user;

  ReminderProvider({this.user, ReminderService? service})
      : _reminderService = service ?? ReminderService() {
    sorter = user?.reminderSorter ?? ReminderSorter();
    startTimer();
  }

  void startTimer() {
    syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (user?.syncOnline ?? false) {
        _syncRepo();
      } else {
        _reminderService.clearDeletesLocalRepo();
      }
    });
  }

  void setUser({User? user}) {
    user = user;
    sorter = user?.reminderSorter ?? sorter;
    notifyListeners();
  }

  SortMethod get sortMethod => sorter.sortMethod;

  set sortMethod(SortMethod method) {
    if (method == sorter.sortMethod) {
      sorter.descending = !sorter.descending;
    } else {
      sorter.sortMethod = method;
      sorter.descending = false;
    }
    user?.reminderSorter = sorter;
    notifyListeners();
  }

  bool get descending => sorter.descending;

  List<SortMethod> get sortMethods => ReminderSorter.sortMethods;

  Future<void> _syncRepo() async {
    // Not quite sure how to handle this outside of gui warning.
    try {
      _reminderService.syncRepo();
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    notifyListeners();
  }

  Future<void> createReminder({
    required String name,
    // DateTime? startDate,
    DateTime? dueDate,
    // DateTime? warnDate,
    // bool? repeatable,
    // List<bool>? repeatDays,
    // int? repeatSkip,
    // Frequency? frequency,
    // CustomFrequency? customFreq
  }) async {
    dueDate = dueDate ??
        DateTime.now()
            .copyWith(hour: Constants.eod.hour, minute: Constants.eod.minute);
    if (DateTime.now().isAfter(dueDate)) {
      dueDate = dueDate.add(const Duration(minutes: 5));
    }

    curReminder = Reminder(
      name: name,
      dueDate: dueDate,
      // repeatable: repeatable ?? false,
      // repeatDays: repeatDays ?? List.filled(7, false, growable: false),
      // repeatSkip: repeatSkip ?? 1,
      // frequency: frequency ?? Frequency.once,
      // customFreq: customFreq ?? CustomFrequency.weekly,
      lastUpdated: DateTime.now(),
    );

    // if(curReminder!.repeatable)
    //   {
    //     curReminder!.repeatID = curReminder.hashCode;
    //
    //   }

    curReminder!.notificationID = curReminder.hashCode;

    try {
      _reminderService.createReminder(reminder: curReminder!);
      scheduleNotification();
    } on FailureToCreateException catch (e) {
      log(e.cause);
      cancelNotification();
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      curReminder!.isSynced = false;
      return updateReminder();
    }
    notifyListeners();
  }

  Future<void> updateReminder() async {
    curReminder!.lastUpdated = DateTime.now();
    cancelNotification();
    if (validateWarnDate()) {
      scheduleNotification();
    }

    try {
      _reminderService.updateReminder(reminder: curReminder!);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      cancelNotification();
      return Future.error(e);
    }
    notifyListeners();
  }

  Future<void> deleteReminder() async {
    cancelNotification();
    try {
      await _reminderService.deleteReminder(reminder: curReminder!);
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    notifyListeners();
  }

  Future<void> reorderReminders(
      {required int oldIndex, required int newIndex}) async {
    try {
      _reminderService.reorderReminders(
          reminders: reminders, oldIndex: oldIndex, newIndex: newIndex);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    notifyListeners();
  }

  // If adding repeating events.
  // Future<void> checkRepeating({DateTime? now}) async =>
  //     _reminderService.checkRepeating(now: now ?? DateTime.now());
  // Future<void> nextRepeat() async => _reminderService.nextRepeatable(reminder: curReminder!);
  // // This also cancels upcoming notifications.
  // Future<void> deleteFutures() async => _reminderService.deleteFutures(reminder: curReminder!);
  // Future<void> populateCalendar({DateTime? limit}) async =>
  //     _reminderService.populateCalendar(limit: limit ?? DateTime.now());

  Future<List<Reminder>> getReminders({int limit = 50, int offset = 0}) async =>
      await _reminderService.getReminders(limit: limit, offset: offset);

  Future<void> setReminders({int limit = 50, int offset = 0}) async =>
      reminders =
          await _reminderService.getReminders(limit: limit, offset: offset);

  Future<List<Reminder>> getRemindersBy(
          {int limit = 50, int offset = 0}) async =>
      await _reminderService.getRemindersBy(
          sorter: sorter, limit: limit, offset: offset);

  Future<void> setRemindersBy({int limit = 50, int offset = 0}) async =>
      reminders = await _reminderService.getRemindersBy(
          sorter: sorter, limit: limit, offset: offset);

  Future<List<Reminder>> getOverdues({int limit = 50, int offset = 0}) =>
      _reminderService.getOverdues(limit: limit, offset: offset);

  Future<List<Reminder>> searchReminders(
          {required String searchString}) async =>
      _reminderService.searchReminders(searchString: searchString);

  Future<List<Reminder>> mostRecent({int limit = 5}) async =>
      await _reminderService.mostRecent(limit: 5);

  Future<Reminder?> getReminderByID({required int id}) async =>
      await _reminderService.getReminderByID(id: id);

  Future<void> setReminderByID({required int id}) async =>
      curReminder = await _reminderService.getReminderByID(id: id) ??
          Reminder(
              name: '',
              dueDate: DateTime.now().copyWith(
                  hour: Constants.midnight.hour,
                  minute: Constants.midnight.minute),
              //  repeatDays: List.filled(7, false),
              lastUpdated: DateTime.now());

  Future<void> scheduleNotification() async {
    String newDue = Jiffy.parseFromDateTime(curReminder!.dueDate)
        .toLocal()
        .yMMMMEEEEdjm
        .toString();
    _notificationService.scheduleNotification(
        id: curReminder!.notificationID!,
        warnDate: curReminder!.dueDate,
        message: "${curReminder!.name} IS DUE: $newDue",
        payload: "REMINDER\n${curReminder!.notificationID}");
  }

  Future<void> cancelNotification() async {
    _notificationService.cancelNotification(id: curReminder!.notificationID!);
  }

  bool validateWarnDate({DateTime? warnDate}) => _notificationService
      .validateWarnDate(warnDate: warnDate ?? curReminder!.dueDate);
}
