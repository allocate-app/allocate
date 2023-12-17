import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../model/task/subtask.dart';
import '../services/subtask_service.dart';
import '../util/exceptions.dart';

class SubtaskProvider extends ChangeNotifier {
  bool rebuild = true;
  final SubtaskService _subtaskService;

  // Not sure if I need a ptr, or a usr pref.
  Subtask? curSubtask;
  List<Subtask> subtasks = [];

  SubtaskProvider() : _subtaskService = SubtaskService();

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
      curSubtask = await _subtaskService.createSubtask(subtask: curSubtask!);
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
      curSubtask = await _subtaskService.updateSubtask(subtask: subtask);
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
      await _subtaskService.updateBatch(subtasks: subtasks);
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
      await _subtaskService.deleteSubtask(subtask: subtask);
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    notifyListeners();
  }

  Future<List<Subtask>> reorderSubtasks(
      {required List<Subtask> subtasks,
      required int oldIndex,
      required int newIndex}) async {
    try {
      return await _subtaskService.reorderSubtasks(
          subtasks: subtasks, oldIndex: oldIndex, newIndex: newIndex);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  // This is going unused atm.
  Future<List<Subtask>> getSubtasksBy() async =>
      await _subtaskService.getSubtasksBy();
}
