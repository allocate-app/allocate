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

class ToDoProvider extends ChangeNotifier {
  bool rebuild = true;
  late Timer syncTimer;

  final ToDoService _toDoService;

  ToDo? curToDo;

  List<ToDo> toDos = [];

  List<ToDo> secondaryToDos = [];

  late ToDoSorter sorter;

  User? user;

  int myDayWeight = 0;

  ToDoProvider({this.user, ToDoService? service})
      : _toDoService = service ?? ToDoService() {
    sorter = user?.toDoSorter ?? ToDoSorter();
    init();
  }

  Future<void> init() async {
    startTimer();
    setMyDayWeight();
  }

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

  int calculateWeight({List<SubTask>? subTasks}) =>
      _toDoService.calculateWeight(subTasks: subTasks);

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

  Future<void> _syncRepo() async {
    try {
      _toDoService.syncRepo();
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
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
    List<SubTask>? subTasks,
  }) async {
    List<SubTask> buffer =
        List.generate(Constants.numTasks[taskType]!, (index) => SubTask());

    if (null != subTasks && buffer.isNotEmpty) {
      List.copyRange(buffer, 0, subTasks, 0, Constants.numTasks[taskType]!);
    }

    subTasks = buffer;

    weight = weight ?? _toDoService.calculateWeight(subTasks: subTasks);
    expectedDuration = expectedDuration ?? (const Duration(hours: 1)).inSeconds;
    realDuration = realDuration ??
        _toDoService.calculateRealDuration(
            weight: weight, duration: expectedDuration);
    startDate =
        startDate?.copyWith(second: 0, microsecond: 0, millisecond: 0) ??
            DateTime.now().copyWith(
                hour: Constants.midnight.hour,
                minute: Constants.midnight.minute,
                second: 0,
                millisecond: 0,
                microsecond: 0);
    dueDate = dueDate?.copyWith(second: 0, microsecond: 0, millisecond: 0) ??
        startDate.copyWith();

    if (startDate.isAfter(dueDate)) {
      dueDate = startDate.copyWith(minute: startDate.minute + 15);
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
        completed: completed ?? false,
        repeatable: repeatable ?? false,
        frequency: frequency ?? Frequency.once,
        repeatDays: repeatDays ?? List.filled(7, false, growable: false),
        repeatSkip: repeatSkip ?? 1,
        subTasks: subTasks,
        lastUpdated: DateTime.now());

    if (repeatable ?? false) {
      curToDo!.repeatID = Constants.generateID();
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

    notifyListeners();
  }

  Future<void> updateToDo({ToDo? toDo}) async {
    await updateToDoAsync(toDo: toDo ?? curToDo!);
    notifyListeners();
  }

  Future<void> updateToDoAsync({ToDo? toDo}) async {
    toDo = toDo ?? curToDo!;
    toDo.lastUpdated = DateTime.now();
    if (toDo.repeatable && null == toDo.repeatID) {
      toDo.repeatID = Constants.generateID();
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
}
