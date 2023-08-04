import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:jiffy/jiffy.dart';

import '../model/task/deadline.dart';
import '../model/user/user.dart';
import '../services/deadline_service.dart';
import '../services/notification_service.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/sorting/deadline_sorter.dart';

class DeadlineProvider extends ChangeNotifier {
  late Timer syncTimer;

  final DeadlineService _deadlineService;
  // Singleton for now. DI later.
  final NotificationService _notificationService = NotificationService.instance;

  late Deadline curDeadline;

  late List<Deadline> deadlines;

  late DeadlineSorter sorter;

  User? user;
  DeadlineProvider({this.user, DeadlineService? service})
      : _deadlineService = service ?? DeadlineService() {
    sorter = user?.deadlineSorter ?? DeadlineSorter();
    startTimer();
  }

  void startTimer() {
    syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (user!.syncOnline) {
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
    notifyListeners();
  }

  bool get descending => sorter.descending;

  List<SortMethod> get sortMethods => DeadlineSorter.sortMethods;

  Future<void> _syncRepo() async {
    // Not quite sure how to handle this outside of gui warning.
    try {
      _deadlineService.syncRepo();
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      rethrow;
    } on FailureToUploadException catch (e) {
      log(e.cause);
      rethrow;
    }
    notifyListeners();
  }

  Future<void> createDeadLine({
    required String name,
    String description = "",
    DateTime? startDate,
    DateTime? dueDate,
    DateTime? warnDate,
    bool warnMe = false,
    Priority priority = Priority.low,
    bool? repeatable,
    Frequency? frequency,
    CustomFrequency? customFreq,
    List<bool>? repeatDays,
    int? repeatSkip,
  }) async {
    startDate = startDate ?? DateTime.now();
    dueDate = dueDate ??
        DateTime(startDate.year, startDate.month, startDate.day, 23, 59, 0);

    if (startDate.isAfter(dueDate)) {
      dueDate = startDate.add(const Duration(days: 1));
    }

    warnDate = warnDate ?? dueDate;

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
      customFreq: customFreq ?? CustomFrequency.weekly,
      repeatDays: repeatDays ?? List.filled(7, false),
      repeatSkip: repeatSkip ?? 1,
    );

    curDeadline.repeatID = curDeadline.hashCode;
    curDeadline.notificationID = curDeadline.hashCode;

    try {
      _deadlineService.createDeadline(deadline: curDeadline);

      if (curDeadline.warnMe) {
        scheduleNotification();
      }
    } on FailureToCreateException catch (e) {
      log(e.cause);
      cancelNotification();
      rethrow;
    } on FailureToUploadException catch (e) {
      log(e.cause);
      curDeadline.isSynced = false;
      return updateDeadline();
    }
    notifyListeners();
  }

  Future<void> updateDeadline() async {
    cancelNotification();
    if (curDeadline.warnMe) {
      scheduleNotification();
    }
    try {
      _deadlineService.updateDeadline(deadline: curDeadline);
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

  Future<void> deleteDeadline() async {
    try {
      _deadlineService.deleteDeadline(deadline: curDeadline);
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      rethrow;
    }
    notifyListeners();
  }

  Future<void> reorderDeadlines(
      {required int oldIndex, required int newIndex}) async {
    try {
      _deadlineService.reorderDeadlines(
          deadlines: deadlines, oldIndex: oldIndex, newIndex: newIndex);
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
      _deadlineService.checkRepeating(now: now ?? DateTime.now());
  Future<void> nextRepeat() async =>
      _deadlineService.nextRepeatable(deadline: curDeadline);
  // This also cancels upcoming notifications.
  Future<void> deleteFutures() async =>
      _deadlineService.deleteFutures(deadline: curDeadline);
  Future<void> populateCalendar({DateTime? limit}) async =>
      _deadlineService.populateCalendar(limit: limit ?? DateTime.now());

  Future<void> getDeadlines() async =>
      deadlines = await _deadlineService.getDeadlines();
  Future<void> getDeadlinesBy() async =>
      deadlines = await _deadlineService.getDeadlinesBy(sorter: sorter);

  // These are for grabbing from payload.
  Future<void> getDeadlineByID({required int id}) async =>
      curDeadline = await _deadlineService.getDeadlineByID(id: id) ??
          Deadline(
              name: "",
              startDate: DateTime.now(),
              dueDate: DateTime.now().add(const Duration(days: 1)),
              warnDate: DateTime.now().add(const Duration(days: 1)),
              repeatDays: List.filled(7, false));

  Future<void> scheduleNotification() async {
    String newDue =
        Jiffy.parseFromDateTime(curDeadline.dueDate).toLocal().toString();
    _notificationService.scheduleNotification(
        id: curDeadline.notificationID!,
        warnDate: curDeadline.warnDate,
        message: "${curDeadline.name} IS DUE: $newDue",
        payload: "DEADLINE\n${curDeadline.notificationID}");
  }

  Future<void> cancelNotification() async {
    _notificationService.cancelNotification(id: curDeadline.notificationID!);
  }
}
