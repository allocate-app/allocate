import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../../model/task/subtask.dart';
import '../../repositories/subtask_repo.dart';
import '../../util/constants.dart';
import '../../util/exceptions.dart';
import '../../util/interfaces/repository/model/subtask_repository.dart';
import '../viewmodels/user_viewmodel.dart';

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

  late UserViewModel? userViewModel;
  Subtask? curSubtask;
  List<Subtask> subtasks = [];

  // CONSTRUCTOR
  SubtaskProvider({SubtaskRepository? subtaskRepository, this.userViewModel})
      : _subtaskRepo = subtaskRepository ?? SubtaskRepo.instance {
    _subtaskRepo.addListener(notifyListeners);
  }

  Future<void> init() async {
    await _subtaskRepo.init();
    notifyListeners();
  }

  void forceRefreshState() {
    _subtaskRepo.forceRefreshState();
  }

  void setUser({UserViewModel? newUser}) {
    if (newUser == userViewModel) {
      return;
    }
    userViewModel = newUser;
    notifyListeners();
  }

  Future<void> refreshRepo() async {
    try {
      await _subtaskRepo.refreshRepo();
      notifyListeners();
    } on FailureToDeleteException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on FailureToUploadException catch (e, stacktrace) {
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
      await _subtaskRepo.syncRepo();
      notifyListeners();
    } on FailureToDeleteException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on FailureToUploadException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> createSubtask(Subtask subtask) async {
    try {
      // Check for db collisions.
      bool inDB = await _subtaskRepo.containsID(id: subtask.id);

      while (inDB) {
        subtask.id = subtask.id + 1;
        inDB = await _subtaskRepo.containsID(id: subtask.id);
      }

      curSubtask = await _subtaskRepo.create(subtask);
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

  Future<void> updateSubtask({Subtask? subtask}) async {
    subtask = subtask ?? curSubtask!;
    subtask.lastUpdated = DateTime.now();
    try {
      curSubtask = await _subtaskRepo.update(subtask);
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

  Future<void> updateBatch({List<Subtask>? subtasks}) async {
    subtasks = subtasks ?? this.subtasks;
    for (Subtask subtask in subtasks) {
      subtask.lastUpdated = DateTime.now();
    }
    try {
      await _subtaskRepo.updateBatch(subtasks);
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

  Future<void> deleteSubtask({required Subtask subtask}) async {
    try {
      await _subtaskRepo.delete(subtask);
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

  // ATM, no real need to restore -> Subtasks aren't deleted until parent object is removed
  Future<void> emptyTrash() async {
    try {
      await _subtaskRepo.emptyTrash();
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
      await _subtaskRepo.deleteSweep();
    } on FailureToDeleteException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> clearDatabase() async {
    curSubtask = null;
    subtasks = [];
    _rebuild = false;
    await _subtaskRepo.clearDB();
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
      subtasks[i].lastUpdated = DateTime.now();
    }
    try {
      await _subtaskRepo.updateBatch(subtasks);
      return subtasks;
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

  Future<List<Subtask>> getDeleted(
          {int limit = Constants.minLimitPerQuery, int offset = 0}) async =>
      await _subtaskRepo.getDeleted(limit: limit, offset: offset);
}
