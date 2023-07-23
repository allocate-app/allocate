import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../model/task/reminder.dart';
import '../model/user/user.dart';
import '../services/reminder_service.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/sorting/reminder_sorter.dart';

class ReminderProvider extends ChangeNotifier {
  late Timer syncTimer;
  final ReminderService _reminderService;

  late Reminder curReminder;

  late List<Reminder> reminders;

  List<Reminder> failCache = List.empty(growable: true);

  late ReminderSorter sorter;

  User? user;
  ReminderProvider({this.user, ReminderService? service})
      : _reminderService = service ?? ReminderService() {
    sorter = user?.reminderSorter ?? ReminderSorter();
    startTimer();
  }

  void setUser({User? user}) {
    user = user;
    sorter = user?.reminderSorter ?? sorter;
    notifyListeners();
  }

  void startTimer() {
    syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _reattemptUpdate();
      if (user!.syncOnline) {
        _syncRepo();
      } else {
        _reminderService.clearDeletesLocalRepo();
      }
    });
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
      log("This is a fatal error.");
    } on FailureToUploadException catch (e) {
      log(e.cause);
      log("This is a fatal error, supabase issue");
    }
    notifyListeners();
  }

  Future<void> createReminder(
      {required String name,
      DateTime? startDate,
      DateTime? dueDate,
      bool? repeatable,
      List<bool>? repeatDays,
      int? repeatSkip,
      Frequency? frequency,
      CustomFrequency? customFreq}) async {
    curReminder = Reminder(
      name: name,
      startDate: startDate ?? DateTime.now(),
      dueDate: dueDate ?? DateTime.now(),
      repeatable: repeatable ?? false,
      repeatDays: repeatDays ?? List.filled(7, false, growable: false),
      repeatSkip: repeatSkip ?? 1,
      frequency: frequency ?? Frequency.once,
      customFreq: customFreq ?? CustomFrequency.weekly,
    );

    // Set the id on creation.
    if (curReminder.repeatable) {
      curReminder.repeatID = curReminder.id;
    }

    try {
      _reminderService.createReminder(reminder: curReminder);
    } on FailureToCreateException catch (e) {
      log(e.cause);
      failCache.add(curReminder);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      updateReminder();
      return;
    }

    notifyListeners();
  }

  Future<void> updateReminder(
      {String? name,
      DateTime? startDate,
      DateTime? dueDate,
      bool? repeatable,
      List<bool>? repeatDays,
      int? repeatSkip,
      Frequency? frequency,
      CustomFrequency? customFreq}) async {
    Reminder reminder = curReminder.copyWith(
        name: name,
        startDate: startDate,
        dueDate: dueDate,
        repeatable: repeatable,
        repeatSkip: repeatSkip,
        frequency: frequency,
        customFreq: customFreq);

    reminder.id = curReminder.id;
    reminder.customViewIndex = curReminder.customViewIndex;

    if (reminder.repeatable) {
      reminder.repeatID = curReminder.repeatID ?? curReminder.id;
    }

    curReminder = reminder;

    try {
      _reminderService.updateReminder(reminder: curReminder);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      failCache.add(curReminder);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      failCache.add(curReminder);
    }
    notifyListeners();
  }

  Future<void> _reattemptUpdate() async {
    try {
      _reminderService.updateBatch(reminders: failCache);
      failCache.clear();
    } on FailureToUploadException catch (e) {
      log("DataCache - ${e.cause}");
    } on FailureToUpdateException catch (e) {
      log("DataCache - ${e.cause}");
    }
    notifyListeners();
  }

  Future<void> deleteReminder() async {
    try {
      _reminderService.deleteReminder(reminder: curReminder);
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      failCache.add(curReminder);
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
      failCache.addAll(reminders);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      failCache.addAll(reminders);
    }
    notifyListeners();
  }

  Future<void> getRoutinesBy() async {
    reminders = await _reminderService.getRemindersBy(sorter: sorter);
    notifyListeners();
  }
}
