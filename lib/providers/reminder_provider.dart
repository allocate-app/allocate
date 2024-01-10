import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:jiffy/jiffy.dart';

import '../model/task/reminder.dart';
import '../model/user/user.dart';
import '../repositories/reminder_repo.dart';
import '../services/notification_service.dart';
import '../services/repeatable_service.dart';
import '../util/constants.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/interfaces/repository/model/reminder_repository.dart';
import '../util/sorting/reminder_sorter.dart';

class ReminderProvider extends ChangeNotifier {
  bool _rebuild = true;

  bool get rebuild => _rebuild;

  set rebuild(bool rebuild) {
    _rebuild = rebuild;
    if (_rebuild) {
      reminders = [];
      secondaryReminders = [];
      notifyListeners();
    }
  }

  set softRebuild(bool rebuild) {
    _rebuild = rebuild;

    if (_rebuild) {
      reminders = [];
      secondaryReminders = [];
    }
  }

  late final ReminderRepository _reminderRepo;
  late final RepeatableService _repeatService;

  final NotificationService _notificationService = NotificationService.instance;

  Reminder? curReminder;

  List<Reminder> reminders = [];
  List<Reminder> secondaryReminders = [];

  late ReminderSorter sorter;

  User? user;

  // CONSTRUCTOR
  ReminderProvider(
      {this.user,
      RepeatableService? repeatableService,
      ReminderRepository? reminderRepository})
      : sorter = user?.reminderSorter ?? ReminderSorter(),
        _repeatService = repeatableService ?? RepeatableService.instance,
        _reminderRepo = reminderRepository ?? ReminderRepo.instance;

  void setUser({User? newUser}) {
    user = newUser;
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

  List<SortMethod> get sortMethods => sorter.sortMethods;

  Future<void> createReminder({
    required String name,
    DateTime? dueDate,
    bool? repeatable,
    List<bool>? repeatDays,
    int? repeatSkip,
    Frequency? frequency,
  }) async {
    if (null != dueDate) {
      dueDate = dueDate.copyWith(second: 0, microsecond: 0, millisecond: 0);
    }

    curReminder = Reminder(
      name: name,
      originalDue: dueDate,
      dueDate: dueDate,
      repeatable: repeatable ?? false,
      repeatDays: repeatDays ?? List.filled(7, false, growable: false),
      repeatSkip: repeatSkip ?? 1,
      frequency: frequency ?? Frequency.once,
      lastUpdated: DateTime.now(),
    );

    curReminder!.notificationID = Constants.generate32ID();
    curReminder!.repeatID = Constants.generateID();

    try {
      curReminder = await _reminderRepo.create(curReminder!);

      await scheduleNotification(reminder: curReminder);
      if (curReminder!.repeatable) {
        await createTemplate(reminder: curReminder);
      }
    } on FailureToCreateException catch (e) {
      log(e.cause);
      await cancelNotification();
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      curReminder!.isSynced = false;
      return await updateReminder();
    }
    notifyListeners();
  }

  Future<void> updateReminder({Reminder? reminder}) async {
    await updateReminderAsync(reminder: reminder);
    notifyListeners();
  }

  Future<void> updateReminderAsync({Reminder? reminder}) async {
    reminder = reminder ?? curReminder!;
    reminder.lastUpdated = DateTime.now();

    if (reminder.repeatable && null == reminder.repeatID) {
      reminder.repeatID = Constants.generateID();
    }
    try {
      curReminder = await _reminderRepo.update(curReminder!);
      if (curReminder!.repeatable) {
        Reminder? template =
            await _reminderRepo.getTemplate(repeatID: curReminder!.repeatID!);
        if (null == template) {
          curReminder!.originalDue = curReminder!.dueDate;
          await createTemplate(reminder: curReminder!);
        }
      }
      await cancelNotification(reminder: curReminder);
      if (validateDueDate(dueDate: curReminder!.dueDate)) {
        await scheduleNotification(reminder: curReminder);
      }
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      await cancelNotification();
      return Future.error(e);
    }
  }

  Future<void> deleteReminder({Reminder? reminder}) async {
    reminder = reminder ?? curReminder!;
    await cancelNotification(reminder: reminder);
    try {
      await _reminderRepo.delete(reminder);
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    notifyListeners();
  }

  Future<void> removeReminder({Reminder? reminder}) async {
    if (null == reminder) {
      return;
    }
    try {
      await _reminderRepo.remove(reminder);
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      return Future.error(e);
    }

    notifyListeners();
  }

  Future<void> restoreReminder({Reminder? reminder}) async {
    if (null == reminder) {
      return;
    }
    reminder.toDelete = false;
    reminder.repeatable = false;
    reminder.frequency = Frequency.once;
    try {
      curReminder = await _reminderRepo.update(reminder);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    notifyListeners();
  }

  Future<void> emptyTrash() async {
    try {
      List<int> ids = await _reminderRepo.emptyTrash();
      await _notificationService.cancelMultiple(ids: ids);
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    notifyListeners();
  }

  Future<List<Reminder>> reorderReminders(
      {List<Reminder>? reminders,
      required int oldIndex,
      required int newIndex}) async {
    reminders = reminders ?? this.reminders;

    if (oldIndex < newIndex) {
      newIndex--;
    }
    Reminder reminder = reminders.removeAt(oldIndex);
    reminders.insert(newIndex, reminder);
    for (int i = 0; i < reminders.length; i++) {
      reminders[i].customViewIndex = i;
    }
    try {
      await _reminderRepo.updateBatch(reminders);
      return reminders;
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
      await _repeatService.nextRepeat(model: reminder ?? curReminder!);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<void> handleRepeating(
      {Reminder? reminder, bool? single = false, bool delete = false}) async {
    try {
      return await _repeatService.handleRepeating(
          model: reminder, single: single, delete: delete);

      //TODO: Clear key -> run repeat routine.
    } on InvalidRepeatingException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<void> createTemplate({Reminder? reminder}) async {
    if (null == reminder) {
      return;
    }
    Reminder template = reminder.copyWith(
        repeatableState: RepeatableState.template, lastUpdated: DateTime.now());
    await _reminderRepo.create(template);
  }

  Future<List<int>> deleteFutures({Reminder? reminder}) async {
    try {
      return await _repeatService.deleteFutures(
          model: reminder ?? curReminder!);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<void> deleteAndCancelFutures({Reminder? reminder}) async {
    List<int> cancelIDs = await deleteFutures(reminder: reminder);
    await _notificationService.cancelMultiple(ids: cancelIDs);
  }

  Future<List<Reminder>> getReminders({int limit = 50, int offset = 0}) async =>
      await _reminderRepo.getRepoList(limit: limit, offset: offset);

  Future<List<Reminder>> getRemindersBy(
          {int limit = 50, int offset = 0}) async =>
      await _reminderRepo.getRepoListBy(
          sorter: sorter, limit: limit, offset: offset);

  Future<List<Reminder>> getDeleted(
          {int limit = Constants.minLimitPerQuery, int offset = 0}) async =>
      await _reminderRepo.getDeleted(limit: limit, offset: offset);

  Future<List<Reminder>> getOverdues({int limit = 50, int offset = 0}) async =>
      await _reminderRepo.getOverdues(limit: limit, offset: offset);

  Future<List<Reminder>> getUpcoming({int limit = 5, int offset = 0}) async =>
      await _reminderRepo.getUpcoming(limit: limit, offset: offset);

  Future<List<Reminder>> searchReminders(
          {required String searchString, bool toDelete = false}) async =>
      await _reminderRepo.search(
          searchString: searchString, toDelete: toDelete);

  Future<List<Reminder>> mostRecent({int limit = 5}) async =>
      await _reminderRepo.mostRecent(limit: 5);

  Future<Reminder?> getReminderByID({int? id}) async {
    if (null == id) {
      return null;
    }
    return await _reminderRepo.getByID(id: id);
  }

  Future<void> scheduleNotification({Reminder? reminder}) async {
    reminder = reminder ?? curReminder!;
    if (null == reminder.dueDate) {
      return;
    }
    String newDue = Jiffy.parseFromDateTime(reminder.dueDate!)
        .toLocal()
        .format(pattern: "MMM d, hh:mm a")
        .toString();
    await _notificationService.scheduleNotification(
        id: reminder.notificationID!,
        warnDate: reminder.dueDate!,
        message:
            "${reminder.name} is due on: $newDue\n It's okay to ask for more time.",
        payload: "REMINDER\n${reminder.id}");
  }

  Future<void> cancelNotification({Reminder? reminder}) async {
    reminder = reminder ?? curReminder!;
    await _notificationService.cancelNotification(id: reminder.notificationID!);
  }

  bool validateDueDate({DateTime? dueDate}) =>
      _notificationService.validateNotificationDate(notificationDate: dueDate);

  Future<List<Reminder>> getRemindersBetween(
          {DateTime? start, DateTime? end}) async =>
      await _reminderRepo.getRange(start: start, end: end);
}
