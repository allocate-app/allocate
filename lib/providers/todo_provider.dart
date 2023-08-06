import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../model/task/subtask.dart';
import '../model/task/todo.dart';
import '../model/user/user.dart';
import '../services/todo_service.dart';
import '../util/constants.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/sorting/todo_sorter.dart';

// NOTE: Use futurebuilder for UI.

class ToDoProvider extends ChangeNotifier {
  late Timer syncTimer;

  final ToDoService _toDoService;

  ToDo? curToDo;

  late List<ToDo> toDos;

  late ToDoSorter sorter;

  User? user;
  ToDoProvider({this.user, ToDoService? service})
      : _toDoService = service ?? ToDoService() {
    sorter = user?.toDoSorter ?? ToDoSorter();
    init();
  }

  Future<void> init() async {
    startTimer();
  }

  void startTimer() {
    syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
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
    notifyListeners();
  }

  bool get descending => sorter.descending;

  List<SortMethod> get sortMethods => ToDoSorter.sortMethods;

  Future<int> getMyDayWeight() async => _toDoService.getMyDayWeight();

  Future<void> recalculateWeight() async {
    _toDoService.recalculateWeight(toDo: curToDo!);
    updateToDo();
  }

  Future<void> recalculateRealDuration() async {
    _toDoService.setRealDuration(toDo: curToDo!);
    updateToDo();
  }

  Future<void> _syncRepo() async {
    try {
      _toDoService.syncRepo();
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      rethrow;
    } on FailureToUploadException catch (e) {
      log(e.cause);
      rethrow;
    }
    notifyListeners();
  }

  // Subtasks are fixed length.
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
    List<SubTask> buffer =
        List.filled(Constants.numTasks[taskType]!, SubTask());

    if (null != subTasks && buffer.isNotEmpty) {
      List.copyRange(buffer, 0, subTasks, 0, Constants.numTasks[taskType]!);
    }

    subTasks = buffer;

    weight = weight ?? _toDoService.calculateWeight(subTasks: subTasks);
    int expectedDuration =
        duration?.inSeconds ?? (const Duration(hours: 1)).inSeconds;
    int realDuration = _toDoService.calculateRealDuration(
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
        subTasks: subTasks);

    curToDo!.repeatID = curToDo.hashCode;

    try {
      _toDoService.createToDo(toDo: curToDo!);
    } on FailureToCreateException catch (e) {
      log(e.cause);
      rethrow;
    } on FailureToUploadException catch (e) {
      log(e.cause);
      curToDo!.isSynced = false;
      return updateToDo();
    }
    notifyListeners();
  }

  Future<void> updateToDo() async {
    if (curToDo!.taskType != TaskType.small) {
      _toDoService.recalculateWeight(toDo: curToDo!);
    }
    _toDoService.setRealDuration(toDo: curToDo!);

    try {
      _toDoService.updateToDo(toDo: curToDo!);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      rethrow;
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      rethrow;
    }
    notifyListeners();
  }

  Future<void> deleteToDo() async {
    try {
      _toDoService.deleteToDo(toDo: curToDo!);
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      rethrow;
    }
    notifyListeners();
  }

  Future<void> reorderToDos(
      {required int oldIndex, required int newIndex}) async {
    try {
      _toDoService.reorderTodos(
          toDos: toDos, oldIndex: oldIndex, newIndex: newIndex);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      rethrow;
    } on FailureToUploadException catch (e) {
      log(e.cause);
      rethrow;
    }
  }

  Future<void> checkRepeating({DateTime? now}) async =>
      _toDoService.checkRepeating(now: now ?? DateTime.now());

  Future<void> nextRepeat() async =>
      _toDoService.nextRepeatable(toDo: curToDo!);

  Future<void> deleteFutures() async =>
      _toDoService.deleteFutures(toDo: curToDo!);

  // TODO: Finish testing.
  Future<void> populateCalendar({DateTime? limit}) async =>
      _toDoService.populateCalendar(limit: limit ?? DateTime.now());

  // TODO: Refactor this to throw an error - Catch & Create.
  Future<void> getToDoByID({required int id}) async =>
      curToDo = await _toDoService.getToDoByID(id: id) ??
          ToDo(
              taskType: TaskType.small,
              name: '',
              expectedDuration: 0,
              realDuration: 0,
              startDate: DateTime.now(),
              dueDate: DateTime.now(),
              repeatDays: List.filled(7, false),
              subTasks:
                  List.filled(Constants.numTasks[TaskType.small]!, SubTask()));

  Future<void> getToDos() async {
    toDos = await _toDoService.getToDos();
  }

  Future<void> getToDosBy() async {
    toDos = await _toDoService.getToDosBy(toDoSorter: sorter);
  }

  Future<void> getMyDay() async {
    toDos = await _toDoService.getMyDay();
  }

  Future<void> getCompleted() async {
    toDos = await _toDoService.getCompleted();
  }
}
