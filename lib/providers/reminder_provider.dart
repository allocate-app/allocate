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
  List<Reminder> recentReminders = [];

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
    DateTime? startDate,
    DateTime? dueDate,
    bool? repeatable,
    List<bool>? repeatDays,
    int? repeatSkip,
    Frequency? frequency,
  }) async {
    dueDate = dueDate?.copyWith(second: 0, microsecond: 0, millisecond: 0) ??
        DateTime.now().copyWith(
            hour: Constants.eod.hour,
            minute: Constants.eod.minute,
            second: 0,
            microsecond: 0,
            millisecond: 0);
    if (DateTime.now().isAfter(dueDate)) {
      dueDate = dueDate.copyWith(
          day: dueDate.day + 1,
          hour: Constants.midnight.hour,
          minute: Constants.midnight.minute);
    }

    curReminder = Reminder(
      name: name,
      dueDate: dueDate,
      repeatable: repeatable ?? false,
      repeatDays: repeatDays ?? List.filled(7, false, growable: false),
      repeatSkip: repeatSkip ?? 1,
      frequency: frequency ?? Frequency.once,
      lastUpdated: DateTime.now(),
    );

    if (curReminder!.repeatable) {
      curReminder!.repeatID = curReminder.hashCode;
    }

    curReminder!.notificationID = curReminder.hashCode;

    try {
      await _reminderService.createReminder(reminder: curReminder!);
      await scheduleNotification();
    } on FailureToCreateException catch (e) {
      log(e.cause);
      cancelNotification();
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      curReminder!.isSynced = false;
      return await updateReminder();
    }
    notifyListeners();
  }

  Future<void> updateReminder() async {
    await updateReminderAsync();
    notifyListeners();
  }

  Future<void> updateReminderAsync() async {
    curReminder!.lastUpdated = DateTime.now();
    if (curReminder!.repeatable && null == curReminder!.repeatID) {
      curReminder!.repeatID = curReminder!.hashCode;
    }
    await cancelNotification();
    if (validateWarnDate()) {
      await scheduleNotification();
    }

    try {
      return await _reminderService.updateReminder(reminder: curReminder!);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      cancelNotification();
      return Future.error(e);
    }
  }

  Future<void> deleteReminder({Reminder? reminder}) async {
    await cancelNotification();
    try {
      await _reminderService.deleteReminder(reminder: reminder ?? curReminder!);
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    notifyListeners();
  }

  Future<List<Reminder>> reorderReminders(
      {required int oldIndex, required int newIndex}) async {
    try {
      return await _reminderService.reorderReminders(
          reminders: reminders, oldIndex: oldIndex, newIndex: newIndex);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<void> checkRepeating({DateTime? now}) async {
    try {
      await _reminderService.checkRepeating(now: now ?? DateTime.now());
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<void> nextRepeat({Reminder? reminder}) async {
    try {
      await _reminderService.nextRepeatable(reminder: reminder ?? curReminder!);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<List<Reminder>> deleteFutures({Reminder? reminder}) async {
    try {
      return await _reminderService.deleteFutures(
          reminder: reminder ?? curReminder!);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<void> deleteAndCancelFutures({Reminder? reminder}) async {
    await deleteFutures(reminder: reminder).then((toDelete) async {
      List<int> cancelIDs =
          toDelete.map((reminder) => reminder.notificationID!).toList();
      return await _notificationService.cancelFutures(ids: cancelIDs);
    });
  }

  Future<void> populateCalendar({DateTime? limit}) async {
    try {
      return await _reminderService.populateCalendar(
          limit: limit ?? DateTime.now());
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

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

  Future<List<Reminder>> getOverdues({int limit = 50, int offset = 0}) async =>
      await _reminderService.getOverdues(limit: limit, offset: offset);

  Future<List<Reminder>> getUpcoming({int limit = 5, int offset = 0}) async =>
      await _reminderService.getUpcoming(limit: limit, offset: offset);

  Future<List<Reminder>> searchReminders(
          {required String searchString}) async =>
      await _reminderService.searchReminders(searchString: searchString);

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
              repeatDays: List.filled(7, false),
              lastUpdated: DateTime.now());

  Future<void> scheduleNotification() async {
    String newDue = Jiffy.parseFromDateTime(curReminder!.dueDate)
        .toLocal()
        .format(pattern: "yMMMMEEEEdjm")
        .toString();
    await _notificationService.scheduleNotification(
        id: curReminder!.notificationID!,
        warnDate: curReminder!.dueDate,
        message: "${curReminder!.name} IS DUE: $newDue",
        payload: "REMINDER\n${curReminder!.notificationID}");
  }

  Future<void> cancelNotification() async {
    await _notificationService.cancelNotification(
        id: curReminder!.notificationID!);
  }

  bool validateWarnDate({DateTime? warnDate}) => _notificationService
      .validateWarnDate(warnDate: warnDate ?? curReminder!.dueDate);

  Future<List<Reminder>> getRemindersBetween(
          {DateTime? start, DateTime? end}) async =>
      await _reminderService.getRange(start: start, end: end);
}
