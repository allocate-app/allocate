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
  bool _rebuild = true;

  bool get rebuild => _rebuild;

  set rebuild(bool rebuild) {
    _rebuild = rebuild;
    if (_rebuild) {
      notifyListeners();
    }
  }

  set softRebuild(bool rebuild) {
    _rebuild = rebuild;
  }

  late Timer syncTimer;

  final DeadlineService _deadlineService;

  // Singleton for now. DI later.
  final NotificationService _notificationService = NotificationService.instance;

  Deadline? curDeadline;

  List<Deadline> deadlines = [];
  List<Deadline> secondaryDeadlines = [];

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

  void setUser({User? newUser}) {
    user = newUser;
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
      await _deadlineService.syncRepo();
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
    if (null != startDate) {
      startDate = startDate.copyWith(second: 0, millisecond: 0, microsecond: 0);
    }
    if (null != dueDate) {
      dueDate = dueDate.copyWith(second: 0, microsecond: 0, millisecond: 0);
    }
    if (null != startDate && null != dueDate && startDate.isAfter(dueDate)) {
      dueDate = startDate.copyWith(
          day: dueDate.day + 1,
          hour: Constants.midnight.hour,
          minute: Constants.midnight.minute);
    }

    warnDate = warnDate?.copyWith(second: 0, millisecond: 0, microsecond: 0) ??
        dueDate;

    if (null != startDate && null != warnDate && startDate.isAfter(warnDate)) {
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

    try {
      curDeadline =
          await _deadlineService.createDeadline(deadline: curDeadline!);

      if (curDeadline!.warnMe) {
        curDeadline!.notificationID = Constants.generate32ID();
        await scheduleNotification(deadline: curDeadline);
      }

      if (repeatable ?? false) {
        curDeadline!.repeatID = Constants.generateID();
        await nextRepeat(deadline: curDeadline);
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
      curDeadline = await _deadlineService
          .updateDeadline(deadline: curDeadline!)
          .whenComplete(() {
        print("update done");
      });
      await cancelNotification(deadline: curDeadline);
      if (deadline.warnMe &&
          validateWarnDate(warnDate: curDeadline!.warnDate)) {
        deadline.notificationID =
            deadline.notificationID ?? Constants.generateID();
        await scheduleNotification(deadline: deadline);
      }
      if (deadline.repeatable && null == deadline.repeatID) {
        deadline.repeatID = Constants.generateID();
        await nextRepeat(deadline: deadline);
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
      await _deadlineService
          .deleteDeadline(deadline: deadline)
          .whenComplete(() {
        print("Delete done");
      });
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      return Future.error(e);
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
  // Future<void> checkRepeating({DateTime? now}) async {
  //   try {
  //     await _deadlineService.checkRepeating(now: now ?? DateTime.now());
  //   } on FailureToUpdateException catch (e) {
  //     log(e.cause);
  //     return Future.error(e);
  //   } on FailureToUploadException catch (e) {
  //     log(e.cause);
  //     return Future.error(e);
  //   }
  // }

  Future<void> nextRepeat({Deadline? deadline}) async {
    print("calling internal repeat");
    try {
      await _deadlineService
          .nextRepeatable(deadline: deadline ?? curDeadline!)
          .whenComplete(() {
        print("internal repeat done");
      });
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<List<int>> deleteFutures({Deadline? deadline}) async {
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
    List<int> cancelIDs = await deleteFutures(deadline: deadline);
    await _notificationService.cancelFutures(ids: cancelIDs);
  }

  Future<void> populateCalendar({DateTime? limit}) async {
    return;
    // try {
    //   return await _deadlineService.populateCalendar(
    //       limit: limit ?? DateTime.now());
    // } on FailureToUpdateException catch (e) {
    //   log(e.cause);
    //   return Future.error(e);
    // } on FailureToUploadException catch (e) {
    //   log(e.cause);
    //   return Future.error(e);
    // }
  }

  Future<List<Deadline>> getDeadlines(
          {int limit = Constants.minLimitPerQuery, int offset = 0}) async =>
      await _deadlineService.getDeadlinesBy(
          sorter: sorter, limit: limit, offset: offset);

  Future<void> setDeadlines() async =>
      deadlines = await _deadlineService.getDeadlines();

  Future<List<Deadline>> getDeadlinesBy(
          {int limit = Constants.minLimitPerQuery, int offset = 0}) async =>
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
    if (null == deadline.dueDate || null == deadline.warnDate) {
      return;
    }
    String newDue = Jiffy.parseFromDateTime(deadline.dueDate!)
        .toLocal()
        .format(pattern: "MMM d, hh:mm a")
        .toString();
    await _notificationService.scheduleNotification(
        id: deadline.notificationID!,
        warnDate: deadline.warnDate!,
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
      _notificationService.validateNotificationDate(notificationDate: warnDate);

  Future<List<Deadline>> getDeadlinesBetween(
          {DateTime? start, DateTime? end}) async =>
      await _deadlineService.getRange(start: start, end: end);
}
