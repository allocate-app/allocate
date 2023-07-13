import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../model/task/deadline.dart';
import '../services/deadline_service.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/interfaces/sorting/deadline_sorter.dart';

class DeadlineProvider extends ChangeNotifier {
  DeadlineProvider();

  final DeadlineService _deadlineService = DeadlineService();

  late Deadline curDeadline;

  late List<Deadline> deadlines;

  List<Deadline> failCache = List.empty(growable: true);

  DeadlineSorter sorter = DeadlineSorter();

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

  Future<void> createDeadLine(
      {required String name,
      String description = "",
      DateTime? startDate,
      DateTime? dueDate,
      DateTime? warnDate,
      bool warnMe = false,
      Priority priority = Priority.low}) async {
    // TODO: Fix.
    curDeadline = Deadline(
      name: name,
      description: description,
      startDate: startDate,
      dueDate: dueDate,
      warnMe: warnMe,
      warnDate: warnDate,
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

  // Future<void> _updateBatch({required List<Deadline> deadlines}) async {
  //   try {
  //     _deadlineService.updateBatch(deadlines: deadlines);
  //   } on FailureToUploadException catch (e) {
  //     log(e.cause);
  //     failCache.addAll(deadlines);
  //   } on FailureToUpdateException catch (e) {
  //     log(e.cause);
  //     failCache.addAll(deadlines);
  //   }
  // }

  Future<void> _reattemptUpdate() async {
    try {
      _deadlineService.retry(deadlines: failCache);
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
