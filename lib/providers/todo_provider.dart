import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../model/task/subtask.dart';
import '../model/task/todo.dart';
import '../model/user/user.dart';
import '../services/subtask_service.dart';
import '../services/todo_service.dart';
import '../util/constants.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/sorting/todo_sorter.dart';

class ToDoProvider extends ChangeNotifier {
  bool rebuild = true;

  // TODO: change timer.
  late Timer syncTimer;

  final ToDoService _toDoService;
  final SubtaskService _subtaskService;

  ToDo? curToDo;

  List<ToDo> toDos = [];

  List<ToDo> secondaryToDos = [];

  late ToDoSorter sorter;

  User? user;

  int myDayWeight = 0;

  final Map<int, ValueNotifier<int>> toDoSubtaskCounts = {
    Constants.intMax: ValueNotifier<int>(0),
  };

  ToDoProvider(
      {this.user, ToDoService? toDoService, SubtaskService? subtaskService})
      : _toDoService = toDoService ?? ToDoService(),
        _subtaskService = subtaskService ?? SubtaskService() {
    sorter = user?.toDoSorter ?? ToDoSorter();
    init();
  }

  Future<void> init() async {
    startTimer();
    setMyDayWeight();
  }

  // This is just for testing atm.
  void startTimer() {
    syncTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (user?.syncOnline ?? false) {
        _syncRepo();
      } else {
        _toDoService.clearDeletesLocalRepo();
      }
    });
  }

  void setUser({User? user}) {
    user = user;
    sorter = user?.toDoSorter ?? sorter;
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
    user?.toDoSorter = sorter;
    notifyListeners();
  }

  bool get descending => sorter.descending;

  int calculateRealDuration({int? weight, int? duration}) =>
      _toDoService.calculateRealDuration(weight: weight, duration: duration);

  Future<int> getWeight(
          {required int taskID, int limit = Constants.maxNumTasks}) async =>
      await _subtaskService.getTaskSubtaskWeight(taskID: taskID, limit: limit);

  // int calculateWeight({List<Subtask>? subtasks}) =>
  //     _toDoService.calculateWeight(subtasks: subtasks);

  List<SortMethod> get sortMethods => sorter.sortMethods;

  Future<int> getMyDayWeight() async => await _toDoService.getMyDayWeight();

  Future<void> setMyDayWeight() async => myDayWeight = await getMyDayWeight();

  Future<void> recalculateWeight() async {
    _toDoService.recalculateWeight(toDo: curToDo!);
    await updateToDo();
  }

  Future<void> recalculateRealDuration() async {
    _toDoService.setRealDuration(toDo: curToDo!);
    await updateToDo();
  }

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
        await _subtaskService.getTaskSubtasksCount(taskID: id, limit: limit);
    if (toDoSubtaskCounts.containsKey(id)) {
      toDoSubtaskCounts[id]?.value = count;
    } else {
      toDoSubtaskCounts[id] = ValueNotifier<int>(count);
    }
  }

  Future<void> _syncRepo() async {
    try {
      await _toDoService.syncRepo();
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    notifyListeners();
  }

  Future<void> createToDo({
    required TaskType taskType,
    required String name,
    int? groupID,
    int? groupIndex,
    String? description,
    int? weight,
    int? expectedDuration,
    int? realDuration,
    Priority? priority,
    DateTime? startDate,
    DateTime? dueDate,
    bool? myDay,
    bool? completed,
    bool? repeatable,
    Frequency? frequency,
    List<bool>? repeatDays,
    int? repeatSkip,
    List<Subtask>? subtasks,
  }) async {
    weight = weight ??
        await getWeight(
            taskID: Constants.intMax, limit: Constants.numTasks[taskType]!);
    expectedDuration = expectedDuration ?? (const Duration(hours: 1)).inSeconds;
    realDuration = realDuration ??
        _toDoService.calculateRealDuration(
            weight: weight, duration: expectedDuration);
    subtasks =
        subtasks ?? await _subtaskService.getTaskSubtasks(id: Constants.intMax);

    if (null != startDate && null != dueDate && startDate.isAfter(dueDate)) {
      dueDate = startDate.copyWith(minute: startDate.minute + 15);
    }

    curToDo = ToDo(
        groupID: groupID,
        groupIndex: groupIndex ?? -1,
        taskType: taskType,
        name: name,
        description: description ?? "",
        weight: weight,
        expectedDuration: expectedDuration,
        realDuration: realDuration,
        priority: priority ?? Priority.low,
        startDate: startDate,
        dueDate: dueDate,
        myDay: myDay ?? false,
        completed: completed ?? false,
        repeatable: repeatable ?? false,
        frequency: frequency ?? Frequency.once,
        repeatDays: repeatDays ?? List.filled(7, false, growable: false),
        repeatSkip: repeatSkip ?? 1,
        subtasks: subtasks,
        lastUpdated: DateTime.now());

    if (repeatable ?? false) {
      curToDo!.repeatID = Constants.generateID();
      nextRepeat(toDo: curToDo);
    }

    try {
      curToDo = await _toDoService.createToDo(toDo: curToDo!);
    } on FailureToCreateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      curToDo!.isSynced = false;
      return await updateToDo();
    }

    await _updateSubtasks(subtasks: subtasks, taskID: curToDo!.id);
    toDoSubtaskCounts[Constants.intMax]!.value = 0;

    notifyListeners();
  }

  // Future<void> createSubtask({required int taskID, int? index}) async {
  //   Subtask subtask = Subtask(taskID: taskID, lastUpdated: DateTime.now());
  //   if (null != index) {
  //     subtask.customViewIndex = index;
  //   }
  //   try {
  //     subtask = await _subtaskService.createSubtask(
  //         subtask: Subtask(taskID: taskID, lastUpdated: DateTime.now()));
  //   } on FailureToUploadException catch (e) {
  //     log(e.cause);
  //     return Future.error(e);
  //   } on FailureToUpdateException catch (e) {
  //     log(e.cause);
  //     return Future.error(e);
  //   }
  //   notifyListeners();
  // }

  Future<void> updateToDo({ToDo? toDo}) async {
    await updateToDoAsync(toDo: toDo ?? curToDo!);
    notifyListeners();
  }

  Future<void> updateToDoAsync({ToDo? toDo}) async {
    toDo = toDo ?? curToDo!;
    toDo.lastUpdated = DateTime.now();
    if (toDo.repeatable && null == toDo.repeatID) {
      toDo.repeatID = Constants.generateID();
      nextRepeat(toDo: toDo);
    }

    try {
      curToDo = await _toDoService.updateToDo(toDo: toDo);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  // Future<void> updateSubtask({required Subtask subtask}) async {
  //   subtask.lastUpdated = DateTime.now();
  //   try {
  //     subtask = await _subtaskService.updateSubtask(subtask: subtask);
  //   } on FailureToUploadException catch (e) {
  //     log(e.cause);
  //     return Future.error(e);
  //   } on FailureToUpdateException catch (e) {
  //     log(e.cause);
  //     return Future.error(e);
  //   }
  //   notifyListeners();
  // }

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
    // for (int i = 0; i < subtasks.length; i++) {
    //   subtasks[i].taskID = taskID;
    //   subtasks[i].customViewIndex = i;
    //   subtasks[i].lastUpdated = DateTime.now();
    // }
    try {
      await _subtaskService.updateBatch(subtasks: subtasks);
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
      await _toDoService.updateBatch(toDos: toDos);
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
    toDo = toDo ?? curToDo!;
    try {
      await _toDoService.deleteToDo(toDo: toDo);
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      return Future.error(e);
    }

    notifyListeners();
  }

  // Future<void> deleteSubtask({required Subtask subtask}) async {
  //   try {
  //     await _subtaskService.deleteSubtask(subtask: subtask);
  //   } on FailureToDeleteException catch (e) {
  //     log(e.cause);
  //     return Future.error(e);
  //   }
  //   notifyListeners();
  // }

  Future<List<ToDo>> reorderToDos(
      {required int oldIndex, required int newIndex, List<ToDo>? toDos}) async {
    try {
      return await _toDoService.reorderTodos(
          toDos: toDos ?? this.toDos, oldIndex: oldIndex, newIndex: newIndex);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<void> checkRepeating({DateTime? now}) async {
    try {
      await _toDoService.checkRepeating(now: now ?? DateTime.now());
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  // Future<List<Subtask>> reorderSubtasks(
  //     {required List<Subtask> subtasks,
  //     required int oldIndex,
  //     required int newIndex}) async {
  //   try {
  //     return await _subtaskService.reorderSubtasks(
  //         subtasks: subtasks, oldIndex: oldIndex, newIndex: newIndex);
  //   } on FailureToUpdateException catch (e) {
  //     log(e.cause);
  //     return Future.error(e);
  //   } on FailureToUploadException catch (e) {
  //     log(e.cause);
  //     return Future.error(e);
  //   }
  // }

  Future<void> nextRepeat({ToDo? toDo}) async {
    try {
      await _toDoService.nextRepeatable(toDo: toDo ?? curToDo!);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<void> deleteFutures({ToDo? toDo}) async {
    try {
      await _toDoService.deleteFutures(toDo: toDo ?? curToDo!);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<void> populateCalendar({DateTime? limit}) async {
    try {
      return await _toDoService.populateCalendar(
          limit: limit ?? DateTime.now());
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<List<ToDo>> getOverdues({int limit = 50, int offset = 0}) async =>
      await _toDoService.getOverdues(limit: limit, offset: offset);

  Future<List<ToDo>> getUpcoming({int limit = 5, int offset = 0}) async =>
      await _toDoService.getUpcoming(limit: limit, offset: offset);

  Future<List<ToDo>> searchToDos({required String searchString}) async =>
      _toDoService.searchToDos(searchString: searchString);

  Future<List<ToDo>> mostRecent({int limit = 5}) async =>
      await _toDoService.mostRecent(limit: 5);

  Future<ToDo?> getToDoByID({int? id}) async =>
      await _toDoService.getToDoByID(id: id);

  Future<void> setToDoByID({required int id}) async =>
      curToDo = await _toDoService.getToDoByID(id: id);

  Future<List<ToDo>> getToDos({int limit = 50, int offset = 0}) async =>
      await _toDoService.getToDos(limit: limit, offset: offset);

  Future<void> setToDos({int limit = 50, int offset = 0}) async {
    toDos = await _toDoService.getToDos(limit: limit, offset: offset);
  }

  Future<List<ToDo>> getToDosBy({int limit = 50, int offset = 0}) async =>
      _toDoService.getToDosBy(toDoSorter: sorter, limit: limit, offset: offset);

  Future<void> setToDosBy({int limit = 50, int offset = 0}) async {
    toDos = await _toDoService.getToDosBy(
        toDoSorter: sorter, limit: limit, offset: offset);
  }

  Future<List<ToDo>> getMyDay({int limit = 50, int offset = 0}) async =>
      await _toDoService.getMyDay(
          toDoSorter: sorter, limit: limit, offset: offset);

  Future<void> setMyDay({int limit = 50, int offset = 0}) async {
    toDos = await _toDoService.getMyDay(
        toDoSorter: sorter, limit: limit, offset: offset);
  }

  Future<List<ToDo>> getCompletedToDos(
          {int limit = 50, int offset = 0}) async =>
      await _toDoService.getCompleted(
          toDoSorter: sorter, limit: limit, offset: offset);

  Future<void> setToDosCompleted({int limit = 50, int offset = 0}) async {
    toDos = await _toDoService.getCompleted(
        toDoSorter: sorter, limit: limit, offset: offset);
  }

  Future<List<ToDo>> getToDosBetween({DateTime? start, DateTime? end}) async =>
      await _toDoService.getRange(start: start, end: end);

  Future<List<Subtask>> getSubtasks({
    required int id,
    int limit = Constants.maxNumTasks,
    ToDo? toDo,
  }) async {
    return await _subtaskService.getTaskSubtasks(id: id, limit: limit);
  }
}
