import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../model/task/deadline.dart';
import '../model/user/user.dart';
import '../services/deadline_service.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/sorting/deadline_sorter.dart';

class DeadlineProvider extends ChangeNotifier {
  late Timer syncTimer;

  final DeadlineService _deadlineService;

  late Deadline curDeadline;

  late List<Deadline> deadlines;

  List<Deadline> failCache = List.empty(growable: true);

  late DeadlineSorter sorter;

  User? user;
  DeadlineProvider({this.user, DeadlineService? service})
      : _deadlineService = service ?? DeadlineService() {
    sorter = user?.deadlineSorter ?? DeadlineSorter();
    startTimer();
  }

  void startTimer() {
    syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _reattemptUpdate();
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
      log("This is a fatal error.");
    } on FailureToUploadException catch (e) {
      log(e.cause);
      log("This is a fatal error, supabase issue");
    }
    notifyListeners();
  }

  Future<void> createDeadLine(
      {required String name,
      String description = "",
      DateTime? startDate,
      DateTime? dueDate,
      DateTime? warnDate,
      bool warnMe = false,
      Priority priority = Priority.low}) async {
    curDeadline = Deadline(
      name: name,
      description: description,
      startDate: startDate ?? DateTime.now(),
      dueDate: dueDate ?? DateTime.now(),
      warnMe: warnMe,
      warnDate: warnDate ?? DateTime.now(),
      priority: priority,
    );
    try {
      _deadlineService.createDeadline(deadline: curDeadline);
    } on FailureToCreateException catch (e) {
      log(e.cause);
      failCache.add(curDeadline);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      updateDeadline();
      return;
    }
    notifyListeners();
  }

  Future<void> updateDeadline(
      {String? name,
      String? description,
      DateTime? startDate,
      DateTime? dueDate,
      DateTime? warnDate,
      bool? warnMe,
      Priority? priority}) async {
    Deadline deadline = curDeadline.copyWith(
      name: name,
      description: description,
      startDate: startDate,
      dueDate: dueDate,
      warnDate: warnDate,
      warnMe: warnMe,
      priority: priority,
    );

    deadline.id = curDeadline.id;
    deadline.customViewIndex = curDeadline.customViewIndex;
    curDeadline = deadline;
    try {
      _deadlineService.updateDeadline(deadline: curDeadline);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      failCache.add(curDeadline);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      failCache.add(curDeadline);
    }

    notifyListeners();
  }

  Future<void> _reattemptUpdate() async {
    try {
      _deadlineService.updateBatch(deadlines: failCache);
      failCache.clear();
    } on FailureToUploadException catch (e) {
      log("DataCache - ${e.cause}");
    } on FailureToUpdateException catch (e) {
      log("DataCache - ${e.cause}");
    }
    notifyListeners();
  }

  Future<void> deleteDeadline() async {
    try {
      _deadlineService.deleteDeadline(deadline: curDeadline);
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      failCache.add(curDeadline);
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
      failCache.addAll(deadlines);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      failCache.addAll(deadlines);
    }
    notifyListeners();
  }

  Future<void> getDeadlinesBy() async {
    deadlines = await _deadlineService.getDeadlinesBy(sorter: sorter);
    notifyListeners();
  }
}
