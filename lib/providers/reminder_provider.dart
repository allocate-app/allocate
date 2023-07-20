import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../model/task/reminder.dart';
import '../services/reminder_service.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/sorting/reminder_sorter.dart';

class ReminderProvider extends ChangeNotifier {
  ReminderProvider();

  final ReminderService _reminderService = ReminderService();

  late Reminder curReminder;

  late List<Reminder> reminders;

  List<Reminder> failCache = List.empty(growable: true);

  ReminderSorter sorter = ReminderSorter();

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

  Future<void> createReminder({required String name, DateTime? dueDate}) async {
    curReminder = Reminder(name: name, dueDate: dueDate ?? DateTime.now());
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

  Future<void> updateReminder({String? name, DateTime? dueDate}) async {
    Reminder reminder = curReminder.copyWith(name: name, dueDate: dueDate);
    reminder.id = curReminder.id;
    reminder.customViewIndex = curReminder.customViewIndex;
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

  Future<void> _updateBatch({required List<Reminder> reminders}) async {
    try {
      _reminderService.updateBatch(reminders: reminders);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      failCache.addAll(reminders);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      failCache.addAll(reminders);
    }
  }

  Future<void> _reattemptUpdate() async {
    try {
      _reminderService.retry(reminders: failCache);
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
      // Re-store into local database, on total failure, cache.
      _updateBatch(reminders: reminders);
    }
    notifyListeners();
  }

  Future<void> getRoutinesBy() async {
    reminders = await _reminderService.getRemindersBy(sorter: sorter);
    notifyListeners();
  }
}
