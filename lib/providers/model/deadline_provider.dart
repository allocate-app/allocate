import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:jiffy/jiffy.dart';

import '../../model/task/deadline.dart';
import '../../repositories/deadline_repo.dart';
import '../../services/notification_service.dart';
import '../../services/repeatable_service.dart';
import '../../util/constants.dart';
import '../../util/enums.dart';
import '../../util/exceptions.dart';
import '../../util/interfaces/repository/model/deadline_repository.dart';
import '../../util/sorting/deadline_sorter.dart';
import '../viewmodels/user_viewmodel.dart';

class DeadlineProvider extends ChangeNotifier {
  bool _rebuild = true;

  bool get rebuild => _rebuild;

  set rebuild(bool rebuild) {
    _rebuild = rebuild;
    if (_rebuild) {
      deadlines = [];
      secondaryDeadlines = [];
      notifyListeners();
    }
  }

  set softRebuild(bool rebuild) {
    _rebuild = rebuild;
    if (_rebuild) {
      deadlines = [];
      secondaryDeadlines = [];
    }
  }

  final DeadlineRepository _deadlineRepo;
  final RepeatableService _repeatService;

  final NotificationService _notificationService = NotificationService.instance;

  Deadline? curDeadline;

  List<Deadline> deadlines = [];
  List<Deadline> secondaryDeadlines = [];

  late DeadlineSorter sorter;

  UserViewModel? userViewModel;

  DeadlineProvider(
      {this.userViewModel,
      DeadlineRepository? deadlineRepo,
      RepeatableService? repeatableService})
      : _deadlineRepo = deadlineRepo ?? DeadlineRepo.instance,
        _repeatService = repeatableService ?? RepeatableService.instance,
        sorter = userViewModel?.deadlineSorter ?? DeadlineSorter() {
    _deadlineRepo.addListener(scheduleAndNotify);
  }

  Future<void> init() async {
    await _deadlineRepo.init();

    // This happens on repo-sync.
    // // Local notifications implementation for Linux/Windows doesn't have scheduling api.
    // // Must be loaded into memory on init.
    // if (Platform.isLinux || Platform.isWindows) {
    //   await batchNotifications();
    // }
    notifyListeners();
  }

  void forceRefreshState() {
    _deadlineRepo.forceRefreshState();
  }

  Future<void> scheduleAndNotify() async {
    await batchNotifications();
    notifyListeners();
  }

  void setUser({UserViewModel? newUser}) {
    userViewModel = newUser;
    if (userViewModel?.deadlineSorter == sorter) {
      return;
    }
    sorter = userViewModel?.deadlineSorter ?? sorter;
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
    userViewModel?.deadlineSorter = sorter;
    notifyListeners();
  }

  bool get descending => sorter.descending;

  List<SortMethod> get sortMethods => sorter.sortMethods;

  Future<void> refreshRepo() async {
    try {
      await _deadlineRepo.refreshRepo();
      await batchNotifications();
      notifyListeners();
    } on FailureToDeleteException catch (e, stacktrace) {
      notifyListeners();
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

  Future<void> syncRepo() async {
    try {
      await _deadlineRepo.syncRepo();
      await batchNotifications();
      notifyListeners();
    } on FailureToDeleteException catch (e, stacktrace) {
      notifyListeners();
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

  Future<void> createDeadline(Deadline deadline) async {
    try {
      // Check for db collisions.
      bool inDB = await _deadlineRepo.containsID(id: deadline.id);

      while (inDB) {
        deadline.id = deadline.id + 1;
        inDB = await _deadlineRepo.containsID(id: deadline.id);
      }

      curDeadline = await _deadlineRepo.create(deadline);
      if (curDeadline!.repeatable) {
        await createTemplate(deadline: curDeadline!);
      }

      if (curDeadline!.warnMe &&
          validateWarnDate(warnDate: curDeadline!.warnDate)) {
        await scheduleNotification(deadline: curDeadline);
      }
      notifyListeners();
    } on FailureToCreateException catch (e) {
      log(e.cause);
      await cancelNotification(deadline: deadline);
      notifyListeners();
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      deadline.isSynced = false;
      notifyListeners();
      return await updateDeadline(deadline: deadline);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> updateDeadline({Deadline? deadline}) async {
    await updateDeadlineAsync(deadline: deadline);
    notifyListeners();
  }

  Future<void> updateDeadlineAsync({Deadline? deadline}) async {
    deadline = deadline ?? curDeadline;

    if (null == deadline) {
      throw FailureToUpdateException("Invalid model provided");
    }

    try {
      curDeadline = await _deadlineRepo.update(deadline);
      if (curDeadline!.repeatable) {
        Deadline? template =
            await _deadlineRepo.getTemplate(repeatID: curDeadline!.repeatID!);
        if (null == template) {
          curDeadline!.originalStart = curDeadline!.startDate;
          curDeadline!.originalDue = curDeadline!.dueDate;
          curDeadline!.originalWarn = curDeadline!.warnDate;
          await createTemplate(deadline: curDeadline!);
        }
      }
      // This will just update.
      // await cancelNotification(deadline: curDeadline);
      if (deadline.warnMe &&
          validateWarnDate(warnDate: curDeadline!.warnDate)) {
        await scheduleNotification(deadline: deadline);
      }
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      await cancelNotification(deadline: deadline);
      return Future.error(e);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> deleteDeadline({Deadline? deadline}) async {
    if (null == deadline) {
      return;
    }

    await cancelNotification(deadline: deadline);
    try {
      await _deadlineRepo.delete(deadline);
      notifyListeners();
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      notifyListeners();
      return Future.error(e);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> removeDeadline({Deadline? deadline}) async {
    if (null == deadline) {
      return;
    }
    try {
      await _deadlineRepo.remove(deadline);
      notifyListeners();
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      notifyListeners();
      return Future.error(e);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> restoreDeadline({Deadline? deadline}) async {
    if (null == deadline) {
      return;
    }
    deadline.repeatable = false;
    deadline.frequency = Frequency.once;
    deadline.toDelete = false;
    deadline.notificationID = Constants.generate32ID();
    deadline.repeatID = Constants.generateID();
    try {
      curDeadline = await _deadlineRepo.update(deadline);
      notifyListeners();
    } on FailureToUploadException catch (e) {
      log(e.cause);
      notifyListeners();
      return Future.error(e);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      notifyListeners();
      return Future.error(e);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> emptyTrash() async {
    try {
      List<int> ids = await _deadlineRepo.emptyTrash();
      await _notificationService.cancelMultiple(ids: ids);
      notifyListeners();
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      notifyListeners();
      return Future.error(e);
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
        await _deadlineRepo.deleteSweep(upTo: upTo);
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

  // This just schedules the next 10 upcoming notifications.
  // There is a redundancy in repeatedly scheduling the same applications, but
  // This is so that multiple devices remain somewhat synchronized
  // without the need for online push notifications.
  Future<void> batchNotifications() async {
    List<Deadline> toSchedule = await _deadlineRepo.getWarnMes();
    for (Deadline deadline in toSchedule) {
      await scheduleNotification(deadline: deadline);
    }
  }

  Future<void> clearDatabase() async {
    curDeadline = null;
    deadlines = [];
    secondaryDeadlines = [];
    _rebuild = true;
    await _deadlineRepo.clearDB();
    await _notificationService.cancelAllNotifications();
  }

  Future<List<Deadline>> reorderDeadlines(
      {List<Deadline>? deadlines,
      required int oldIndex,
      required int newIndex}) async {
    if (oldIndex < newIndex) {
      newIndex--;
    }
    deadlines = deadlines ?? this.deadlines;
    Deadline deadline = deadlines.removeAt(oldIndex);
    deadlines.insert(newIndex, deadline);
    for (int i = 0; i < deadlines.length; i++) {
      deadlines[i].customViewIndex = i;
    }
    try {
      await _deadlineRepo.updateBatch(deadlines);
      return deadlines;
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  // THIS IS AUTOMATED IN REPEATABLESERVICE.
  Future<void> nextRepeat({Deadline? deadline}) async {
    try {
      await _repeatService.nextRepeat(model: deadline ?? curDeadline!);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> handleRepeating(
      {Deadline? deadline,
      Deadline? delta,
      bool? single = false,
      bool delete = false}) async {
    try {
      await _repeatService.handleRepeating(
          oldModel: deadline, newModel: delta, single: single, delete: delete);
      notifyListeners();
    } on InvalidRepeatingException catch (e) {
      log(e.cause);
      notifyListeners();
      return Future.error(e);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> createTemplate({Deadline? deadline}) async {
    if (null == deadline) {
      return;
    }
    Deadline template = deadline.copyWith(
        repeatableState: RepeatableState.template, lastUpdated: DateTime.now());
    await _deadlineRepo.create(template);
  }

  Future<List<int>> deleteFutures({Deadline? deadline}) async {
    try {
      return await _repeatService.deleteFutures(
          model: deadline ?? curDeadline!);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> deleteAndCancelFutures({Deadline? deadline}) async {
    List<int> cancelIDs = await deleteFutures(deadline: deadline);
    await _notificationService.cancelMultiple(ids: cancelIDs);
  }

  Future<List<Deadline>> getDeleted(
          {int limit = Constants.minLimitPerQuery, int offset = 0}) async =>
      await _deadlineRepo.getDeleted(limit: limit, offset: offset);

  Future<List<Deadline>> getDeadlines(
          {int limit = Constants.minLimitPerQuery, int offset = 0}) async =>
      await _deadlineRepo.getRepoListBy(
          sorter: sorter, limit: limit, offset: offset);

  Future<List<Deadline>> getDeadlinesBy(
          {int limit = Constants.minLimitPerQuery, int offset = 0}) async =>
      await _deadlineRepo.getRepoListBy(
          sorter: sorter, limit: limit, offset: offset);

  Future<List<Deadline>> getOverdues({int limit = 50, int offset = 0}) async =>
      await _deadlineRepo.getOverdues(limit: limit, offset: offset);

  Future<List<Deadline>> getUpcoming({int limit = 5, int offset = 0}) async =>
      await _deadlineRepo.getUpcoming(limit: limit, offset: offset);

  Future<List<Deadline>> searchDeadlines(
          {required String searchString, bool toDelete = false}) async =>
      await _deadlineRepo.search(
          searchString: searchString, toDelete: toDelete);

  Future<List<Deadline>> mostRecent({int limit = 5}) async =>
      await _deadlineRepo.mostRecent(limit: 5);

  Future<Deadline?> getDeadlineByID({int? id}) async {
    if (null == id) {
      return null;
    }
    return await _deadlineRepo.getByID(id: id);
  }

  Future<void> scheduleNotification({Deadline? deadline}) async {
    deadline = deadline ?? curDeadline!;
    if (null == deadline.dueDate || null == deadline.warnDate) {
      return;
    }

    if (!_notificationService.validateNotificationDate(
        notificationDate: deadline.warnDate)) {
      return;
    }

    String newDue = Jiffy.parseFromDateTime(deadline.dueDate!)
        .toLocal()
        .format(pattern: "MMM d, hh:mm a")
        .toString();
    try {
      await _notificationService.scheduleNotification(
          id: deadline.notificationID!,
          warnDate: deadline.warnDate!,
          message:
              "${deadline.name} is due on: $newDue\n It's okay to ask for more time.",
          payload: "DEADLINE\n${deadline.id}");
    } on FailureToScheduleException catch (e, stacktrace) {
      log("${e.cause}\n $stacktrace");
      return Future.error(e);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> cancelNotification({Deadline? deadline}) async {
    deadline = deadline ?? curDeadline!;
    if (null != deadline.notificationID) {
      return await _notificationService.cancelNotification(
          id: deadline.notificationID!);
    }
  }

  bool validateWarnDate({DateTime? warnDate}) =>
      _notificationService.validateNotificationDate(notificationDate: warnDate);

  Future<List<Deadline>> getDeadlinesBetween(
          {DateTime? start, DateTime? end}) async =>
      await _deadlineRepo.getRange(start: start, end: end);
}
