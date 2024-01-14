import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../../model/task/subtask.dart';
import '../../model/task/todo.dart';
import '../../repositories/subtask_repo.dart';
import '../../repositories/todo_repo.dart';
import '../../services/repeatable_service.dart';
import '../../util/constants.dart';
import '../../util/enums.dart';
import '../../util/exceptions.dart';
import '../../util/interfaces/repository/model/subtask_repository.dart';
import '../../util/interfaces/repository/model/todo_repository.dart';
import '../../util/sorting/todo_sorter.dart';
import '../viewmodels/user_viewmodel.dart';

// TODO: IMPLEMENT PROPER GUI ERROR MSGS.
class ToDoProvider extends ChangeNotifier {
  bool _rebuild = true;

  bool get rebuild => _rebuild;

  set rebuild(bool rebuild) {
    _rebuild = rebuild;
    if (_rebuild) {
      toDos = [];
      secondaryToDos = [];
      notifyListeners();
    }
  }

  set softRebuild(bool rebuild) {
    _rebuild = rebuild;

    if (_rebuild) {
      toDos = [];
      secondaryToDos = [];
    }
  }

  final ToDoRepository _toDoRepo;
  final SubtaskRepository _subtaskRepo;
  final RepeatableService _repeatService;

  UserViewModel? userViewModel;

  ToDo? curToDo;

  List<ToDo> toDos = [];
  List<ToDo> secondaryToDos = [];

  late ToDoSorter sorter;

  final Map<int, ValueNotifier<int>> toDoSubtaskCounts = {};

  // CONSTRUCTOR
  ToDoProvider({
    this.userViewModel,
    RepeatableService? repeatService,
    ToDoRepository? toDoRepository,
    SubtaskRepository? subtaskRepository,
  })  : _toDoRepo = toDoRepository ?? ToDoRepo.instance,
        _subtaskRepo = subtaskRepository ?? SubtaskRepo.instance,
        _repeatService = repeatService ?? RepeatableService.instance,
        sorter = userViewModel?.toDoSorter ?? ToDoSorter() {
    init();
  }

  Future<void> init() async {
    // startTimer();

    // TODO: fill the hashmap with repeating events.
    // repeatable subroutine
  }

  void setUser({UserViewModel? newUser}) {
    userViewModel = newUser;
    sorter = userViewModel?.toDoSorter ?? sorter;
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
    userViewModel?.toDoSorter = sorter;
    notifyListeners();
  }

  bool get descending => sorter.descending;

  Future<int> getWeight(
          {required int taskID, int limit = Constants.maxNumTasks}) async =>
      await _subtaskRepo.getTaskSubtaskWeight(taskID: taskID, limit: limit);

  List<SortMethod> get sortMethods => sorter.sortMethods;

  Future<int> getMyDayWeight() async => await _toDoRepo.getMyDayWeight();

  ValueNotifier<int> getSubtaskCount(
      {required int id, int limit = Constants.maxNumTasks}) {
    if (toDoSubtaskCounts.containsKey(id)) {
      return toDoSubtaskCounts[id]!;
    }

    toDoSubtaskCounts[id] = ValueNotifier<int>(0);
    setSubtaskCount(id: id, limit: limit);
    return toDoSubtaskCounts[id]!;
  }

  Future<void> setSubtaskCount(
      {required int id, int limit = Constants.maxNumTasks, int? count}) async {
    count = count ??
        await _subtaskRepo.getTaskSubtasksCount(taskID: id, limit: limit);
    if (toDoSubtaskCounts.containsKey(id)) {
      toDoSubtaskCounts[id]?.value = count;
    } else {
      toDoSubtaskCounts[id] = ValueNotifier<int>(count);
    }
  }

  Future<void> _syncRepo() async {
    try {
      await _toDoRepo.syncRepo();
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    notifyListeners();
  }

  Future<void> createToDo(ToDo toDo) async {
    try {
      curToDo = await _toDoRepo.create(toDo);

      // await _updateSubtasks(subtasks: curToDo!.subtasks, taskID: curToDo!.id);
      if (curToDo!.repeatable) {
        await createTemplate(toDo: curToDo!);
      }
    } on FailureToCreateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      curToDo!.isSynced = false;
      return await updateToDo();
    }

    notifyListeners();
  }

  Future<void> updateToDo({ToDo? toDo}) async {
    await updateToDoAsync(toDo: toDo ?? curToDo!);
    notifyListeners();
  }

  Future<void> updateToDoAsync({ToDo? toDo}) async {
    toDo = toDo ?? curToDo!;
    toDo.lastUpdated = DateTime.now();

    try {
      curToDo = await _toDoRepo.update(toDo);
      if (curToDo!.repeatable) {
        // Try for a template.
        ToDo? template =
            await _toDoRepo.getTemplate(repeatID: curToDo!.repeatID!);
        if (null == template) {
          curToDo!.originalStart = curToDo!.startDate;
          curToDo!.originalDue = curToDo!.dueDate;
          await createTemplate(toDo: curToDo!);
        }
      }
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<void> _updateSubtasks(
      {required List<Subtask> subtasks, required int taskID}) async {
    int i = 0;
    // This eliminates empty subtasks and maintains proper order.
    for (Subtask st in subtasks) {
      if (st.name != "") {
        st.taskID = taskID;
        st.customViewIndex = i++;
        st.lastUpdated = DateTime.now();
      } else {
        st.toDelete = true;
      }
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
  }

  Future<void> updateBatch({List<ToDo>? toDos}) async {
    toDos = toDos ?? this.toDos;
    for (ToDo toDo in toDos) {
      toDo.lastUpdated = DateTime.now();
    }
    try {
      await _toDoRepo.updateBatch(toDos);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    notifyListeners();
  }

  Future<void> deleteToDo({ToDo? toDo}) async {
    if (null == toDo) {
      return;
    }
    try {
      await _toDoRepo.delete(toDo);
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      return Future.error(e);
    }

    notifyListeners();
  }

  Future<void> removeToDo({ToDo? toDo}) async {
    if (null == toDo) {
      return;
    }
    try {
      await _toDoRepo.remove(toDo);
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      return Future.error(e);
    }

    notifyListeners();
  }

  Future<void> restoreToDo({ToDo? toDo}) async {
    if (null == toDo) {
      return;
    }
    toDo.repeatable = false;
    toDo.frequency = Frequency.once;
    toDo.toDelete = false;
    toDo.repeatID = Constants.generateID();
    try {
      curToDo = await _toDoRepo.update(toDo);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    notifyListeners();
  }

  Future<void> emptyTrash() async {
    try {
      List<int> ids = await _toDoRepo.emptyTrash();
      for (int id in ids) {
        List<Subtask> subtasks = await _subtaskRepo.getRepoByTaskID(id: id);
        for (Subtask subtask in subtasks) {
          subtask.toDelete = true;
        }
        await _subtaskRepo.updateBatch(subtasks);
        toDoSubtaskCounts.remove(id);
      }
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    notifyListeners();
  }

  Future<List<ToDo>> reorderToDos(
      {required int oldIndex, required int newIndex, List<ToDo>? toDos}) async {
    toDos = toDos ?? this.toDos;
    if (oldIndex < newIndex) {
      newIndex--;
    }
    ToDo toDo = toDos.removeAt(oldIndex);
    toDos.insert(newIndex, toDo);
    for (int i = 0; i < toDos.length; i++) {
      toDos[i].customViewIndex = i;
    }
    try {
      await _toDoRepo.updateBatch(toDos);
      return toDos;
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<void> nextRepeat({ToDo? toDo}) async {
    try {
      return await _repeatService.nextRepeat(model: toDo ?? curToDo);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<void> handleRepeating(
      {ToDo? toDo,
      ToDo? delta,
      bool? single = false,
      bool delete = false}) async {
    try {
      await _repeatService.handleRepeating(
          oldModel: toDo, newModel: delta, single: single, delete: delete);
    } on InvalidRepeatingException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    notifyListeners();
  }

  Future<void> createTemplate({ToDo? toDo}) async {
    if (null == toDo) {
      return;
    }

    ToDo template = toDo.copyWith(
        repeatableState: RepeatableState.template, lastUpdated: DateTime.now());

    await _toDoRepo.create(template);
  }

  Future<List<int>> deleteFutures({ToDo? toDo}) async {
    try {
      return await _repeatService.deleteFutures(model: toDo ?? curToDo!);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<List<ToDo>> getDeleted(
          {int limit = Constants.minLimitPerQuery, int offset = 0}) async =>
      await _toDoRepo.getDeleted(limit: limit, offset: offset);

  Future<List<ToDo>> getOverdues(
          {int limit = Constants.minLimitPerQuery, int offset = 0}) async =>
      await _toDoRepo.getOverdues(limit: limit, offset: offset);

  Future<List<ToDo>> getUpcoming({int limit = 5, int offset = 0}) async =>
      await _toDoRepo.getUpcoming(limit: limit, offset: offset);

  Future<List<ToDo>> searchToDos(
          {required String searchString, bool toDelete = false}) async =>
      _toDoRepo.search(searchString: searchString, toDelete: toDelete);

  Future<List<ToDo>> mostRecent({int limit = 5}) async =>
      await _toDoRepo.mostRecent(limit: 5);

  Future<ToDo?> getToDoByID({int? id}) async {
    if (null == id) {
      return null;
    }
    return await _toDoRepo.getByID(id: id);
  }

  Future<List<ToDo>> getToDos(
          {int limit = Constants.minLimitPerQuery, int offset = 0}) async =>
      await _toDoRepo.getRepoList(limit: limit, offset: offset);

  Future<List<ToDo>> getToDosBy(
          {int limit = Constants.minLimitPerQuery, int offset = 0}) async =>
      _toDoRepo.getRepoListBy(sorter: sorter, limit: limit, offset: offset);

  Future<List<ToDo>> getMyDay(
          {int limit = Constants.minLimitPerQuery, int offset = 0}) async =>
      await _toDoRepo.getMyDay(sorter: sorter, limit: limit, offset: offset);

  Future<List<ToDo>> getCompletedToDos(
          {int limit = Constants.minLimitPerQuery, int offset = 0}) async =>
      await _toDoRepo.getCompleted(
          sorter: sorter, limit: limit, offset: offset);

  Future<List<ToDo>> getToDosBetween({DateTime? start, DateTime? end}) async =>
      await _toDoRepo.getRange(start: start, end: end);

  Future<List<Subtask>> getSubtasks({
    required int id,
    int limit = Constants.maxNumTasks,
    ToDo? toDo,
  }) async {
    return await _subtaskRepo.getRepoByTaskID(id: id, limit: limit);
  }
}
