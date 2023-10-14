import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:jiffy/jiffy.dart';

import '../model/task/deadline.dart';
import '../model/user/user.dart';
import '../services/deadline_service.dart';
import '../services/notification_service.dart';
import '../util/constants.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/sorting/deadline_sorter.dart';

class DeadlineProvider extends ChangeNotifier {
  bool rebuild = false;
  late Timer syncTimer;

  final DeadlineService _deadlineService;

  // Singleton for now. DI later.
  final NotificationService _notificationService = NotificationService.instance;

  Deadline? curDeadline;

  List<Deadline> deadlines = [];
  List<Deadline> recentDeadlines = [];

  late DeadlineSorter sorter;

  User? user;

  DeadlineProvider({this.user, DeadlineService? service})
      : _deadlineService = service ?? DeadlineService() {
    sorter = user?.deadlineSorter ?? DeadlineSorter();
    startTimer();
  }

  void startTimer() {
    syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (user?.syncOnline ?? false) {
        _syncRepo();
      } else {
        _deadlineService.clearDeletesLocalRepo();
      }
    });
  }

  void setUser({User? user}) {
    user = user;
    sorter = user?.deadlineSorter ?? sorter;
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
    user?.deadlineSorter = sorter;
    notifyListeners();
  }

  bool get descending => sorter.descending;

  List<SortMethod> get sortMethods => sorter.sortMethods;

  Future<void> _syncRepo() async {
    // Not quite sure how to handle this outside of gui warning.
    try {
      _deadlineService.syncRepo();
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    notifyListeners();
  }

  Future<void> createDeadline({
    required String name,
    String description = "",
    DateTime? startDate,
    DateTime? dueDate,
    DateTime? warnDate,
    bool warnMe = false,
    Priority priority = Priority.low,
    bool? repeatable,
    Frequency? frequency,
    List<bool>? repeatDays,
    int? repeatSkip,
  }) async {
    startDate =
        startDate?.copyWith(second: 0, millisecond: 0, microsecond: 0) ??
            DateTime.now().copyWith(
                hour: Constants.midnight.hour,
                minute: Constants.midnight.minute,
                second: 0,
                microsecond: 0,
                millisecond: 0);
    dueDate = dueDate?.copyWith(second: 0, microsecond: 0, millisecond: 0) ??
        DateTime.now().copyWith(
            hour: Constants.eod.hour,
            minute: Constants.eod.minute,
            second: 0,
            microsecond: 0,
            millisecond: 0);
    if (startDate.isAfter(dueDate)) {
      dueDate = startDate.copyWith(
          day: dueDate.day + 1,
          hour: Constants.midnight.hour,
          minute: Constants.midnight.minute);
    }

    warnDate = warnDate?.copyWith(second: 0, millisecond: 0, microsecond: 0) ??
        dueDate;

    if (startDate.isAfter(warnDate)) {
      warnDate = startDate.copyWith(minute: startDate.minute + 15);
    }

    curDeadline = Deadline(
        name: name,
        description: description,
        startDate: startDate,
        dueDate: dueDate,
        warnMe: warnMe,
        warnDate: warnDate,
        priority: priority,
        repeatable: repeatable ?? false,
        frequency: frequency ?? Frequency.once,
        repeatDays: repeatDays ?? List.filled(7, false),
        repeatSkip: repeatSkip ?? 1,
        lastUpdated: DateTime.now());

    if (repeatable ?? false) {
      curDeadline!.repeatID = Constants.generateID();
    }
    if (warnMe) {
      curDeadline!.notificationID = Constants.generateID();
    }

    try {
      curDeadline =
          await _deadlineService.createDeadline(deadline: curDeadline!);

      if (curDeadline!.warnMe) {
        await scheduleNotification();
      }
    } on FailureToCreateException catch (e) {
      log(e.cause);
      await cancelNotification();
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      curDeadline!.isSynced = false;
      return await updateDeadline();
    }
    notifyListeners();
  }

  Future<void> updateDeadline({Deadline? deadline}) async {
    await updateDeadlineAsync(deadline: deadline);
    notifyListeners();
  }

  Future<void> updateDeadlineAsync({Deadline? deadline}) async {
    deadline = deadline ?? curDeadline!;
    deadline.lastUpdated = DateTime.now();

    try {
      curDeadline =
          await _deadlineService.updateDeadline(deadline: curDeadline!);
      await cancelNotification();
      if (deadline.warnMe && validateWarnDate()) {
        deadline.notificationID =
            deadline.notificationID ?? Constants.generateID();
        await scheduleNotification();
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

  Future<void> deleteDeadline({Deadline? deadline}) async {
    deadline = deadline ?? curDeadline!;
    await cancelNotification(deadline: deadline);
    try {
      await _deadlineService.deleteDeadline(deadline: deadline);
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    if (deadline == curDeadline) {
      curDeadline = null;
    }
    notifyListeners();
  }

  Future<List<Deadline>> reorderDeadlines(
      {List<Deadline>? deadlines,
      required int oldIndex,
      required int newIndex}) async {
    try {
      return await _deadlineService.reorderDeadlines(
          deadlines: deadlines ?? this.deadlines,
          oldIndex: oldIndex,
          newIndex: newIndex);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  // This also schedules notifications.
  Future<void> checkRepeating({DateTime? now}) async {
    try {
      await _deadlineService.checkRepeating(now: now ?? DateTime.now());
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<void> nextRepeat({Deadline? deadline}) async {
    try {
      await _deadlineService.nextRepeatable(deadline: deadline ?? curDeadline!);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<List<Deadline>> deleteFutures({Deadline? deadline}) async {
    try {
      return await _deadlineService.deleteFutures(
          deadline: deadline ?? curDeadline!);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<void> deleteAndCancelFutures({Deadline? deadline}) async {
    await deleteFutures(deadline: deadline).then((toDelete) async {
      List<int?> cancelIDs =
          toDelete.map((deadline) => deadline.notificationID).toList();
      return await _notificationService.cancelFutures(ids: cancelIDs);
    });
  }

  Future<void> populateCalendar({DateTime? limit}) async {
    try {
      return await _deadlineService.populateCalendar(
          limit: limit ?? DateTime.now());
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<List<Deadline>> getDeadlines(
          {required int limit, required int offset}) async =>
      await _deadlineService.getDeadlinesBy(
          sorter: sorter, limit: limit, offset: offset);

  Future<void> setDeadlines() async =>
      deadlines = await _deadlineService.getDeadlines();

  Future<List<Deadline>> getDeadlinesBy(
          {required int limit, required int offset}) async =>
      await _deadlineService.getDeadlinesBy(
          sorter: sorter, limit: limit, offset: offset);

  Future<void> setDeadlinesBy() async =>
      deadlines = await _deadlineService.getDeadlinesBy(sorter: sorter);

  Future<List<Deadline>> getOverdues({int limit = 50, int offset = 0}) async =>
      await _deadlineService.getOverdues(limit: limit, offset: offset);

  Future<List<Deadline>> getUpcoming({int limit = 5, int offset = 0}) async =>
      await _deadlineService.getUpcoming(limit: limit, offset: offset);

  Future<List<Deadline>> searchDeadlines(
          {required String searchString}) async =>
      await _deadlineService.searchDeadlines(searchString: searchString);

  Future<List<Deadline>> mostRecent({int limit = 5}) async =>
      await _deadlineService.mostRecent(limit: 5);

  Future<Deadline?> getDeadlineByID({int? id}) async =>
      await _deadlineService.getDeadlineByID(id: id);

  // These are for grabbing from payload.
  Future<void> setDeadlineByID({required int id}) async =>
      curDeadline = await _deadlineService.getDeadlineByID(id: id) ??
          Deadline(
              name: "",
              startDate: DateTime.now(),
              dueDate: DateTime.now().add(const Duration(days: 1)),
              warnDate: DateTime.now().add(const Duration(days: 1)),
              repeatDays: List.filled(7, false),
              lastUpdated: DateTime.now());

  Future<void> scheduleNotification({Deadline? deadline}) async {
    deadline = deadline ?? curDeadline!;
    String newDue = Jiffy.parseFromDateTime(deadline.dueDate)
        .toLocal()
        .format(pattern: "MMM d, hh:mm a")
        .toString();
    await _notificationService.scheduleNotification(
        id: deadline.notificationID!,
        warnDate: deadline.warnDate,
        message:
            "${deadline.name} is due on: $newDue\n It's okay to ask for more time.",
        payload: "DEADLINE\n${deadline.id}");
  }

  Future<void> cancelNotification({Deadline? deadline}) async {
    deadline = deadline ?? curDeadline!;
    if (null != deadline.notificationID) {
      return await _notificationService.cancelNotification(
          id: deadline.notificationID!);
    }
  }

  bool validateWarnDate({DateTime? warnDate}) =>
      _notificationService.validateNotificationDate(
          notificationDate: warnDate ?? curDeadline!.warnDate);

  Future<List<Deadline>> getDeadlinesBetween(
          {DateTime? start, DateTime? end}) async =>
      await _deadlineService.getRange(start: start, end: end);
}
