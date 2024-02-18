import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:jiffy/jiffy.dart';

import '../../model/task/reminder.dart';
import '../../repositories/reminder_repo.dart';
import '../../services/notification_service.dart';
import '../../services/repeatable_service.dart';
import '../../util/constants.dart';
import '../../util/enums.dart';
import '../../util/exceptions.dart';
import '../../util/interfaces/repository/model/reminder_repository.dart';
import '../../util/sorting/reminder_sorter.dart';
import '../viewmodels/user_viewmodel.dart';

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

  UserViewModel? userViewModel;

  // CONSTRUCTOR
  ReminderProvider(
      {this.userViewModel,
      RepeatableService? repeatableService,
      ReminderRepository? reminderRepository})
      : sorter = userViewModel?.reminderSorter ?? ReminderSorter(),
        _repeatService = repeatableService ?? RepeatableService.instance,
        _reminderRepo = reminderRepository ?? ReminderRepo.instance {
    _reminderRepo.addListener(scheduleAndNotify);
  }

  Future<void> init() async {
    _reminderRepo.init();
    notifyListeners();
  }

  Future<void> scheduleAndNotify() async {
    await batchNotifications();
    notifyListeners();
  }

  void setUser({UserViewModel? newUser}) {
    userViewModel = newUser;
    if (userViewModel?.reminderSorter == sorter) {
      return;
    }
    sorter = userViewModel?.reminderSorter ?? sorter;
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
    userViewModel?.reminderSorter = sorter;
    notifyListeners();
  }

  bool get descending => sorter.descending;

  List<SortMethod> get sortMethods => sorter.sortMethods;

  Future<void> syncRepo() async {
    try {
      await _reminderRepo.syncRepo();
      await batchNotifications();
      notifyListeners();
    } on FailureToDeleteException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on FailureToUploadException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on FailureToScheduleException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> createReminder(Reminder reminder) async {
    try {
      curReminder = await _reminderRepo.create(reminder);

      await scheduleNotification(reminder: curReminder);
      if (curReminder!.repeatable) {
        await createTemplate(reminder: curReminder);
      }
      notifyListeners();
    } on FailureToCreateException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      await cancelNotification(reminder: reminder);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on FailureToUploadException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      reminder.isSynced = false;
      notifyListeners();
      return await updateReminder(reminder: reminder);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> updateReminder({Reminder? reminder}) async {
    await updateReminderAsync(reminder: reminder);
    notifyListeners();
  }

  Future<void> updateReminderAsync({Reminder? reminder}) async {
    reminder = reminder ?? curReminder;

    if (null == reminder) {
      throw FailureToUpdateException("Invalid model provided");
    }

    try {
      curReminder = await _reminderRepo.update(reminder);
      if (curReminder!.repeatable) {
        Reminder? template =
            await _reminderRepo.getTemplate(repeatID: curReminder!.repeatID!);
        if (null == template) {
          curReminder!.originalDue = curReminder!.dueDate;
          await createTemplate(reminder: curReminder!);
        }
      }
      // Notifications don't need to be canceled on update.
      // await cancelNotification(reminder: curReminder);
      if (validateDueDate(dueDate: curReminder!.dueDate)) {
        await scheduleNotification(reminder: curReminder);
      }
      notifyListeners();
    } on FailureToUploadException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on FailureToUpdateException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      await cancelNotification(reminder: reminder);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log(e.toString());
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> deleteReminder({Reminder? reminder}) async {
    if (null == reminder) {
      return;
    }
    try {
      await cancelNotification(reminder: reminder);
      await _reminderRepo.delete(reminder);
      notifyListeners();
    } on FailureToDeleteException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> removeReminder({Reminder? reminder}) async {
    if (null == reminder) {
      return;
    }
    try {
      await _reminderRepo.remove(reminder);
      notifyListeners();
    } on FailureToDeleteException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> restoreReminder({Reminder? reminder}) async {
    if (null == reminder) {
      return;
    }
    reminder.toDelete = false;
    reminder.repeatable = false;
    reminder.frequency = Frequency.once;
    reminder.notificationID = Constants.generate32ID();
    reminder.repeatID = Constants.generateID();
    try {
      curReminder = await _reminderRepo.update(reminder);
      notifyListeners();
    } on FailureToUploadException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on FailureToUpdateException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> emptyTrash() async {
    try {
      List<int> ids = await _reminderRepo.emptyTrash();
      await _notificationService.cancelMultiple(ids: ids);
      notifyListeners();
    } on FailureToDeleteException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> dayReset() async {
    try {
      DateTime? upTo = userViewModel?.deleteDate;
      if (null != upTo) {
        await _reminderRepo.deleteSweep(upTo: upTo);
      }
      await batchNotifications();
    } on FailureToDeleteException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      return Future.error(e, stacktrace);
    } on FailureToScheduleException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> batchNotifications() async {
    List<Reminder> toSchedule = await _reminderRepo.getWarnMes();
    for (Reminder reminder in toSchedule) {
      await scheduleNotification(reminder: reminder);
    }
  }

  Future<void> clearDatabase() async {
    curReminder = null;
    reminders = [];
    secondaryReminders = [];
    _rebuild = true;
    await _reminderRepo.clearDB();
    await _notificationService.cancelAllNotifications();
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
    } on FailureToUpdateException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      return Future.error(e, stacktrace);
    } on FailureToUploadException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> nextRepeat({Reminder? reminder}) async {
    try {
      await _repeatService.nextRepeat(model: reminder ?? curReminder!);
    } on FailureToUpdateException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      return Future.error(e, stacktrace);
    } on FailureToUploadException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> handleRepeating(
      {Reminder? reminder,
      Reminder? delta,
      bool? single = false,
      bool delete = false}) async {
    try {
      await _repeatService.handleRepeating(
          oldModel: reminder, newModel: delta, single: single, delete: delete);
      notifyListeners();
    } on InvalidRepeatingException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
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
    } on FailureToUpdateException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      return Future.error(e, stacktrace);
    } on FailureToUploadException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      return Future.error(UnexpectedErrorException(), stacktrace);
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
    reminder = reminder ?? curReminder;
    if (null == reminder || null == reminder.dueDate) {
      return;
    }

    if (!_notificationService.validateNotificationDate(
        notificationDate: reminder.dueDate)) {
      return;
    }

    String newDue = Jiffy.parseFromDateTime(reminder.dueDate!)
        .toLocal()
        .format(pattern: "MMM d, hh:mm a")
        .toString();
    try {
      await _notificationService.scheduleNotification(
          id: reminder.notificationID!,
          warnDate: reminder.dueDate!,
          message:
              "${reminder.name} is due on: $newDue\n It's okay to ask for more time.",
          payload: "REMINDER\n${reminder.id}");
    } on FailureToScheduleException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> cancelNotification({Reminder? reminder}) async {
    if (null == reminder) {
      return;
    }
    await _notificationService.cancelNotification(id: reminder.notificationID!);
  }

  bool validateDueDate({DateTime? dueDate}) =>
      _notificationService.validateNotificationDate(notificationDate: dueDate);

  Future<List<Reminder>> getRemindersBetween(
          {DateTime? start, DateTime? end}) async =>
      await _reminderRepo.getRange(start: start, end: end);
}
