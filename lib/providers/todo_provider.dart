import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../model/task/subtask.dart';
import '../model/task/todo.dart';
import '../model/user/user.dart';
import '../services/todo_service.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/sorting/todo_sorter.dart';

// NOTE: Use futurebuilder for UI.

class ToDoProvider extends ChangeNotifier {
  late Timer syncTimer;
  final ToDoService _todoService;

  late ToDo curToDo;

  late List<ToDo> todos;
  List<ToDo> failCache = List.empty(growable: true);

  late ToDoSorter sorter;

  User? user;
  ToDoProvider({this.user, ToDoService? service})
      : _todoService = service ?? ToDoService() {
    sorter = user?.toDoSorter ?? ToDoSorter();
    startTimer();
  }

  void startTimer() {
    syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _reattemptUpdate();
      if (user!.syncOnline) {
        _syncRepo();
      } else {
        _todoService.clearDeletesLocalRepo();
      }
    });
  }

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

  // Refactor this to set a user instead.
  void setUser({User? user}) {
    user = user;
    sorter = user?.toDoSorter ?? sorter;
    notifyListeners();
  }

  Future<void> recalculateWeight() async {
    _todoService.recalculateWeight(toDo: curToDo);
    updateToDo();
  }

  Future<void> recalculateRealDuration() async {
    _todoService.setRealDuration(toDo: curToDo);
    updateToDo();
  }

  Future<void> _syncRepo() async {
    // Not quite sure how to handle this outside of gui warning.
    try {
      _todoService.syncRepo();
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      log("This is a fatal error.");
    } on FailureToUploadException catch (e) {
      log(e.cause);
      log("This is a fatal error, supabase issue");
    }
    notifyListeners();
  }

  Future<void> createToDo({
    required TaskType taskType,
    required String name,
    int? groupID,
    String? description,
    int? weight,
    Duration? duration,
    Priority? priority,
    DateTime? startDate,
    DateTime? dueDate,
    bool? myDay,
    bool? repeatable,
    Frequency? frequency,
    CustomFrequency? customFreq,
    List<bool>? repeatDays,
    int? repeatSkip,
    List<SubTask>? subTasks,
  }) async {
    weight = weight ?? _todoService.calculateWeight(subTasks: subTasks);
    int expectedDuration =
        duration?.inSeconds ?? (const Duration(hours: 1)).inSeconds;
    int realDuration = _todoService.calculateRealDuration(
        weight: weight, duration: expectedDuration);

    startDate = startDate ?? DateTime.now();
    dueDate = dueDate ??
        DateTime(startDate.year, startDate.month, startDate.day, 23, 59, 0);

    if (startDate.isAfter(dueDate)) {
      dueDate = startDate.add(const Duration(minutes: 15));
    }

    curToDo = ToDo(
        groupID: groupID,
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
        repeatable: repeatable ?? false,
        frequency: frequency ?? Frequency.once,
        customFreq: customFreq ?? CustomFrequency.weekly,
        repeatDays: repeatDays ?? List.filled(7, false, growable: false),
        repeatSkip: repeatSkip ?? 1,
        subTasks: subTasks ?? List.empty(growable: true));

    if (curToDo.repeatable) {
      curToDo.repeatID = curToDo.id;
    }

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
      {int? groupID,
      TaskType? taskType,
      String? name,
      String? description,
      int? weight,
      Duration? duration,
      Priority? priority,
      DateTime? dueDate,
      bool? myDay,
      bool? repeatable,
      Frequency? frequency,
      CustomFrequency? customFrequency,
      List<bool>? repeatDays,
      int? repeatSkip,
      bool? isSynced,
      bool? toDelete,
      List<SubTask>? subTasks}) async {
    int? expectedDuration = duration?.inSeconds;
    int? realDuration = (null == expectedDuration)
        ? null
        : _todoService.calculateRealDuration(
            weight: weight ?? curToDo.weight, duration: expectedDuration);

    ToDo toDo = curToDo.copyWith(
      groupID: groupID,
      taskType: taskType,
      name: name,
      description: description,
      weight: weight,
      expectedDuration: expectedDuration,
      realDuration: realDuration,
      priority: priority,
      dueDate: dueDate,
      myDay: myDay,
      repeatable: repeatable,
      frequency: frequency,
      customFreq: customFrequency,
      repeatDays: repeatDays,
      repeatSkip: repeatSkip,
      subTasks: subTasks,
    );

    if (toDo.weight == 0 && toDo.subTasks.isNotEmpty) {
      _todoService.recalculateWeight(toDo: toDo);
    }

    toDo.id = curToDo.id;

    if (toDo.repeatable) {
      toDo.repeatID = curToDo.repeatID ?? curToDo.id;
    }

    curToDo = toDo;
    try {
      _todoService.updateToDo(toDo: curToDo);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      failCache.add(curToDo);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      failCache.add(curToDo);
    } on ListLimitExceededException catch (e) {
      log(e.cause);
      log("TODO ID: ${curToDo.id}, NAME: ${curToDo.name}");
      // Throw some sort of gui error to re-edit screen & remove tasks.
    }
    notifyListeners();
  }

  Future<void> _reattemptUpdate() async {
    try {
      _todoService.updateBatch(toDos: failCache);
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

  Future<void> nextRepeat() async => _todoService.nextRepeatable(toDo: curToDo);

  Future<void> deleteFutures() async =>
      _todoService.deleteFutures(toDo: curToDo);

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
