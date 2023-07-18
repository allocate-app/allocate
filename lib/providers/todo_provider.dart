import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../model/task/subtask.dart';
import '../model/task/todo.dart';
import '../services/todo_service.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/sorting/todo_sorter.dart';

// NOTE: Use futurebuilder for UI.

class ToDoProvider extends ChangeNotifier {
  // Not sure if I need the user. Tinker with this if needed.
  // Might be an idea for running background timer functions.
  //TODO: refactor -> get a reference to the user instead.
  // On user set, reset the sorter.

  late Timer syncTimer;

  // User? _user;
  ToDoProvider({ToDoSorter? sorter, ToDoService? service})
      : _todoService = service ?? ToDoService(),
        sorter = sorter ?? ToDoSorter();

  final ToDoService _todoService;

  late ToDo curToDo;

  late List<ToDo> todos;
  List<ToDo> failCache = List.empty(growable: true);

  ToDoSorter sorter;

  // Keep these for testing.
  SortMethod get sortMethod => sorter.sortMethod;
  set curSortMethod(SortMethod method) {
    if (method == sorter.sortMethod) {
      sorter.descending = !sorter.descending;
    } else {
      sorter.sortMethod = method;
      sorter.descending = false;
    }
    notifyListeners();
  }

  bool get descending => sorter.descending;
  List<SortMethod> get sortMethods => ToDoSorter.sortMethods;

  void setSorter({ToDoSorter? newSorter}) => sorter = newSorter ?? ToDoSorter();

  void recalculateWeight() => _todoService.recalculateWeight(toDo: curToDo);

  // Not quite sure how to handle weight yet.
  Future<void> createToDo({
    required TaskType taskType,
    required String name,
    String? description,
    int? weight,
    Priority? priority,
    DateTime? dueDate,
    bool? repeatable,
    Frequency? frequency,
    List<bool>? repeatDays,
    int? repeatSkip,
    List<SubTask>? subTasks,
  }) async {
    curToDo = ToDo(
        taskType: taskType,
        name: name,
        description: description ?? "",
        weight: weight ?? 0,
        priority: priority ?? Priority.low,
        dueDate: dueDate,
        repeatable: repeatable ?? false,
        frequency: frequency ?? Frequency.once,
        repeatDays: repeatDays,
        repeatSkip: repeatSkip ?? 1,
        subTasks: subTasks);
    try {
      _todoService.createToDo(toDo: curToDo);
    } on FailureToCreateException catch (e) {
      log(e.cause);
      failCache.add(curToDo);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      failCache.add(curToDo);
      return;
    }
    notifyListeners();
  }

  Future<void> addSubTask({required String name, int? weight}) async {
    SubTask subTask = SubTask(name: name, weight: weight ?? 0);
    try {
      _todoService.addSubTask(subTask: subTask, toDo: curToDo);
    } on ListLimitExceededException catch (e) {
      log(e.cause);
      failCache.add(curToDo);
    }
    notifyListeners();
  }

  Future<void> updateSubTask(
      {required SubTask subTask,
      String? name,
      int? weight,
      bool? completed}) async {
    int index = curToDo.subTasks.indexOf(subTask);
    int oldWeight = subTask.weight;
    SubTask newSubTask = subTask.copyWith(name: name, weight: weight);
    newSubTask.completed = completed ?? subTask.completed;

    try {
      _todoService.updateSubTask(
          oldWeight: oldWeight,
          index: index,
          subTask: newSubTask,
          toDo: curToDo);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      failCache.add(curToDo);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      failCache.add(curToDo);
    }
    notifyListeners();
  }

  Future<void> deleteSubTask({required SubTask subTask}) async {
    try {
      _todoService.deleteSubTask(subTask: subTask, toDo: curToDo);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      failCache.add(curToDo);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      failCache.add(curToDo);
    }

    notifyListeners();
  }

  Future<void> updateToDo(
      {TaskType? taskType,
      String? name,
      String? description,
      int? weight,
      Duration? expectedDuration,
      Priority? priority,
      DateTime? dueDate,
      bool? myDay,
      bool? repeatable,
      Frequency? frequency,
      List<bool>? repeatDays,
      int? repeatSkip,
      bool? isSynced,
      bool? toDelete,
      List<SubTask>? subTasks}) async {
    ToDo toDo = curToDo.copyWith(
      taskType: taskType,
      name: name,
      description: description,
      weight: weight,
      expectedDuration: expectedDuration,
      priority: priority,
      dueDate: dueDate,
      repeatable: repeatable,
      frequency: frequency,
      repeatDays: repeatDays,
      repeatSkip: repeatSkip,
      isSynced: isSynced,
      toDelete: toDelete,
      subTasks: subTasks,
    );

    if (null != expectedDuration &&
        expectedDuration.inSeconds != curToDo.expectedDuration) {
      _todoService.setRealDuration(toDo: toDo);
    }

    if (toDo.weight == 0 && toDo.subTasks.isNotEmpty) {
      _todoService.recalculateWeight(toDo: toDo);
    }

    toDo.id = curToDo.id;
    curToDo = toDo;
    try {
      _todoService.updateToDo(toDo: curToDo);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      failCache.add(curToDo);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      failCache.add(curToDo);
    }
    notifyListeners();
  }

  // Future<void> _updateBatch(List<ToDo> toDos) async {
  //   try {
  //     _todoService.updateBatch(toDos: toDos);
  //   } on FailureToUploadException catch (e) {
  //     log(e.cause);
  //     failCache.addAll(toDos);
  //   } on FailureToUpdateException catch (e) {
  //     log(e.cause);
  //     failCache.addAll(toDos);
  //   }
  // }

  Future<void> _reattemptUpdate() async {
    try {
      _todoService.retry(toDos: failCache);
      failCache.clear();
    } on FailureToUploadException catch (e) {
      log("DataCache - ${e.cause}");
    } on FailureToUpdateException catch (e) {
      log("DataCache - ${e.cause}");
    }
    notifyListeners();
  }

  Future<void> deleteTodo() async {
    try {
      _todoService.deleteToDo(toDo: curToDo);
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      failCache.add(curToDo);
    }
    notifyListeners();
  }

  Future<void> reorderToDos(
      {required int oldIndex, required int newIndex}) async {
    try {
      _todoService.reorderTodos(
          toDos: todos, oldIndex: oldIndex, newIndex: newIndex);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      failCache.addAll(todos);
    }
  }

  Future<void> reorderSubTasks(
      {required int oldIndex, required int newIndex}) async {
    try {
      _todoService.reorderSubTask(
          toDo: curToDo, oldIndex: oldIndex, newIndex: newIndex);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      failCache.add(curToDo);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      failCache.add(curToDo);
    }
    notifyListeners();
  }

  Future<void> getToDos() async {
    todos = await _todoService.getToDos();
  }

  Future<void> getToDosBy() async {
    todos = await _todoService.getToDosBy(todoSorter: sorter);
  }

  Future<void> getMyDay() async {
    todos = await _todoService.getMyDay();
  }

  Future<void> getCompleted() async {
    todos = await _todoService.getCompleted();
  }
}
