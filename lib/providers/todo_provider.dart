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

  final ToDoService _toDoService;

  late ToDo curToDo;

  late List<ToDo> toDos;
  // List<ToDo> failCache = List.empty(growable: true);

  late ToDoSorter sorter;

  User? user;
  ToDoProvider({this.user, ToDoService? service})
      : _toDoService = service ?? ToDoService() {
    sorter = user?.toDoSorter ?? ToDoSorter();
    startTimer();
  }

  void startTimer() {
    syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      //await _reattemptUpdate();
      if (user?.syncOnline ?? false) {
        _syncRepo();
      } else {
        _toDoService.clearDeletesLocalRepo();
      }
    });
  }

  // Keep these for testing.
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

  // Refactor this to set a user instead.
  void setUser({User? user}) {
    user = user;
    sorter = user?.toDoSorter ?? sorter;
    notifyListeners();
  }

  Future<void> recalculateWeight() async {
    _toDoService.recalculateWeight(toDo: curToDo);
    updateToDo();
  }

  Future<void> recalculateRealDuration() async {
    _toDoService.setRealDuration(toDo: curToDo);
    updateToDo();
  }

  Future<void> _syncRepo() async {
    // Not quite sure how to handle this outside of gui warning.
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
        subTasks: subTasks ?? List.empty(growable: true));

    curToDo.repeatID = curToDo.hashCode;

    try {
      _toDoService.createToDo(toDo: curToDo);
    } on FailureToCreateException catch (e) {
      log(e.cause);
      rethrow;
    } on FailureToUploadException catch (e) {
      log(e.cause);
      curToDo.isSynced = false;
      return updateToDo();
    }
    notifyListeners();
  }

  Future<void> updateToDo() async {
    if (curToDo.taskType != TaskType.small) {
      _toDoService.recalculateWeight(toDo: curToDo);
    }
    _toDoService.setRealDuration(toDo: curToDo);

    try {
      _toDoService.updateToDo(toDo: curToDo);
      // These will require to be caught in the gui to alert the user.
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
      _toDoService.deleteToDo(toDo: curToDo);
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      //failCache.add(curToDo);
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
      //failCache.addAll(todos);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      rethrow;
    }
  }

  Future<void> reorderSubTasks(
      {required int oldIndex, required int newIndex}) async {
    try {
      _toDoService.reorderSubTask(
          toDo: curToDo, oldIndex: oldIndex, newIndex: newIndex);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      rethrow;
      // failCache.add(curToDo);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      rethrow;
      // failCache.add(curToDo);
    }
    notifyListeners();
  }

  Future<void> checkRepeating({DateTime? now}) async =>
      _toDoService.checkRepeating(now: now ?? DateTime.now());

  Future<void> nextRepeat() async => _toDoService.nextRepeatable(toDo: curToDo);

  Future<void> deleteFutures() async =>
      _toDoService.deleteFutures(toDo: curToDo);

  // TODO: Finish this implementation. Now, just testable.
  Future<void> populateCalendar({DateTime? limit}) async =>
      _toDoService.populateCalendar(limit: limit ?? DateTime.now());

  // TODO: implement getToDoByID and handle null.

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
