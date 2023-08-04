import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:jiffy/jiffy.dart';

import '../model/task/reminder.dart';
import '../model/user/user.dart';
import '../services/notification_service.dart';
import '../services/reminder_service.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/sorting/reminder_sorter.dart';

class ReminderProvider extends ChangeNotifier {
  late Timer syncTimer;

  final ReminderService _reminderService;
  // Singleton for now. DI later.
  final NotificationService _notificationService = NotificationService.instance;

  late Reminder curReminder;

  late List<Reminder> reminders;

  late ReminderSorter sorter;

  User? user;
  ReminderProvider({this.user, ReminderService? service})
      : _reminderService = service ?? ReminderService() {
    sorter = user?.reminderSorter ?? ReminderSorter();
    startTimer();
  }

  void startTimer() {
    syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (user!.syncOnline) {
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
      rethrow;
    } on FailureToUploadException catch (e) {
      log(e.cause);
      rethrow;
    }
    notifyListeners();
  }

  Future<void> createReminder(
      {required String name,
      DateTime? startDate,
      DateTime? dueDate,
      DateTime? warnDate,
      bool? repeatable,
      List<bool>? repeatDays,
      int? repeatSkip,
      Frequency? frequency,
      CustomFrequency? customFreq}) async {
    startDate = startDate ?? DateTime.now();
    dueDate =
        DateTime(startDate.year, startDate.month, startDate.day, 23, 59, 0);

    if (startDate.isAfter(dueDate)) {
      dueDate = startDate.add(const Duration(minutes: 15));
    }

    warnDate = warnDate ?? dueDate;

    curReminder = Reminder(
      name: name,
      startDate: startDate,
      dueDate: dueDate,
      warnDate: warnDate,
      repeatable: repeatable ?? false,
      repeatDays: repeatDays ?? List.filled(7, false, growable: false),
      repeatSkip: repeatSkip ?? 1,
      frequency: frequency ?? Frequency.once,
      customFreq: customFreq ?? CustomFrequency.weekly,
    );

    curReminder.repeatID = curReminder.hashCode;
    curReminder.notificationID = curReminder.hashCode;

    try {
      _reminderService.createReminder(reminder: curReminder);
      scheduleNotification();
    } on FailureToCreateException catch (e) {
      log(e.cause);
      cancelNotification();
      rethrow;
    } on FailureToUploadException catch (e) {
      log(e.cause);
      curReminder.isSynced = false;
      return updateReminder();
    }
    notifyListeners();
  }

  Future<void> updateReminder() async {
    cancelNotification();
    scheduleNotification();

    try {
      _reminderService.updateReminder(reminder: curReminder);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      rethrow;
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      cancelNotification();
      rethrow;
    }
    notifyListeners();
  }

  Future<void> deleteReminder() async {
    try {
      _reminderService.deleteReminder(reminder: curReminder);
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      rethrow;
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
      rethrow;
    } on FailureToUploadException catch (e) {
      log(e.cause);
      rethrow;
    }
    notifyListeners();
  }

  // This also schedules notifications.
  Future<void> checkRepeating({DateTime? now}) async =>
      _reminderService.checkRepeating(now: now ?? DateTime.now());
  Future<void> nextRepeat() async =>
      _reminderService.nextRepeatable(reminder: curReminder);
  // This also cancels upcoming notifications.
  Future<void> deleteFutures() async =>
      _reminderService.deleteFutures(reminder: curReminder);
  Future<void> populateCalendar({DateTime? limit}) async =>
      _reminderService.populateCalendar(limit: limit ?? DateTime.now());

  Future<void> getReminders() async =>
      reminders = await _reminderService.getReminders();
  Future<void> getRemindersBy() async =>
      reminders = await _reminderService.getRemindersBy(sorter: sorter);

  // For grabbing from payload.
  Future<void> getReminderByID({required int id}) async =>
      curReminder = await _reminderService.getReminderByID(id: id) ??
          Reminder(
              name: '',
              startDate: DateTime.now(),
              dueDate: DateTime.now(),
              warnDate: DateTime.now(),
              repeatDays: List.filled(7, false));

  Future<void> scheduleNotification() async {
    String newDue =
        Jiffy.parseFromDateTime(curReminder.dueDate).toLocal().toString();
    _notificationService.scheduleNotification(
        id: curReminder.notificationID!,
        warnDate: curReminder.warnDate,
        message: "${curReminder.name} IS DUE: $newDue",
        payload: "DEADLINE\n${curReminder.notificationID}");
  }

  Future<void> cancelNotification() async {
    _notificationService.cancelNotification(id: curReminder.notificationID!);
  }
}
