import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../model/task/subtask.dart';
import '../repositories/subtask_repo.dart';
import '../util/constants.dart';
import '../util/exceptions.dart';
import '../util/interfaces/repository/model/subtask_repository.dart';

class SubtaskProvider extends ChangeNotifier {
  bool _rebuild = true;

  bool get rebuild => _rebuild;

  set rebuild(bool rebuild) {
    _rebuild = rebuild;
    if (true == _rebuild) {
      notifyListeners();
    }
  }

  set softRebuild(bool rebuild) {
    _rebuild = rebuild;
  }

  late final SubtaskRepository _subtaskRepo;

  // Not sure if I need a ptr, or a usr pref yet.
  Subtask? curSubtask;
  List<Subtask> subtasks = [];

  // CONSTRUCTOR
  SubtaskProvider({SubtaskRepository? subtaskRepository})
      : _subtaskRepo = subtaskRepository ?? SubtaskRepo.instance;

  Future<void> createSubtask(
      {String? name,
      int? weight,
      bool? completed,
      int? taskID,
      int? index}) async {
    name = name ?? "";
    weight = weight ?? 0;
    completed = completed ?? false;
    curSubtask = Subtask(
        name: name,
        weight: weight,
        completed: completed,
        taskID: taskID,
        lastUpdated: DateTime.now());
    if (null != index) {
      curSubtask?.customViewIndex = index;
    }
    try {
      curSubtask = await _subtaskRepo.create(curSubtask!);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    notifyListeners();
  }

  Future<void> updateSubtask({Subtask? subtask}) async {
    subtask = subtask ?? curSubtask!;
    subtask.lastUpdated = DateTime.now();
    try {
      curSubtask = await _subtaskRepo.update(subtask);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    notifyListeners();
  }

  Future<void> updateBatch({List<Subtask>? subtasks}) async {
    subtasks = subtasks ?? this.subtasks;
    for (Subtask subtask in subtasks) {
      subtask.lastUpdated = DateTime.now();
    }
    try {
      await _subtaskRepo.updateBatch(subtasks);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    notifyListeners();
  }

  Future<void> deleteSubtask({required Subtask subtask}) async {
    try {
      await _subtaskRepo.delete(subtask);
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    notifyListeners();
  }

  // ATM, no real need to restore -> Subtasks aren't deleted until parent object is removed
  Future<void> emptyTrash() async {
    try {
      await _subtaskRepo.emptyTrash();
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    notifyListeners();
  }

  Future<List<Subtask>> reorderSubtasks(
      {List<Subtask>? subtasks,
      required int oldIndex,
      required int newIndex}) async {
    subtasks = subtasks ?? this.subtasks;
    if (oldIndex < newIndex) {
      newIndex--;
    }
    Subtask subtask = subtasks.removeAt(oldIndex);
    subtasks.insert(newIndex, subtask);
    for (int i = 0; i < subtasks.length; i++) {
      subtasks[i].customViewIndex = i;
    }
    try {
      await _subtaskRepo.updateBatch(subtasks);
      return subtasks;
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<List<Subtask>> getDeleted(
          {int limit = Constants.minLimitPerQuery, int offset = 0}) async =>
      await _subtaskRepo.getDeleted(limit: limit, offset: offset);

// This is going unused atm.
// Future<List<Subtask>> getSubtasksBy() async =>
//     await _subtaskRepo.getRepoListBy(sorter: SubtaskSorter());
}
