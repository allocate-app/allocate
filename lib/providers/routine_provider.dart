import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import "../model/task/routine.dart";
import '../model/task/subtask.dart';
import '../model/user/user.dart';
import '../services/routine_service.dart';
import '../services/subtask_service.dart';
import '../util/constants.dart';
import '../util/enums.dart';
import "../util/exceptions.dart";
import '../util/sorting/routine_sorter.dart';

class RoutineProvider extends ChangeNotifier {
  bool rebuild = false;
  late Timer syncTimer;

  final RoutineService _routineService;
  final SubtaskService _subtaskService;

  User? user;
  Routine? curRoutine;

  Routine? _curMorning;
  Routine? _curAfternoon;
  Routine? _curEvening;

  // For testing
  int? _morningID;
  int? _aftID;
  int? _eveID;

  final Map<int, ValueNotifier<int>> routineSubtaskCounts = {
    Constants.intMax: ValueNotifier<int>(0),
  };

  // This should initialize the morning/afternoon/evening routines.
  RoutineProvider(
      {this.user,
      RoutineService? routineService,
      SubtaskService? subtaskService})
      : _routineService = routineService ?? RoutineService(),
        _subtaskService = subtaskService ?? SubtaskService() {
    sorter = user?.routineSorter ?? RoutineSorter();
    init();
  }

  Future<void> init() async {
    await setDailyRoutines();
    startTimer();
  }

  Routine? get curMorning => _curMorning;

  Routine? get curAfternoon => _curAfternoon;

  Routine? get curEvening => _curEvening;

  set curMorning(Routine? newRoutine) {
    _curMorning = newRoutine;
    user?.curMornID = newRoutine?.id;
    // For testing
    _morningID = newRoutine?.id;
  }

  set curAfternoon(Routine? newRoutine) {
    _curAfternoon = newRoutine;
    user?.curAftID = newRoutine?.id;
    // For testing
    _aftID = newRoutine?.id;
  }

  set curEvening(Routine? newRoutine) {
    _curEvening = newRoutine;
    user?.curEveID = newRoutine?.id;
    // For testing
    _eveID = newRoutine?.id;
  }

  void clearRoutines() {
    curMorning = null;
    curAfternoon = null;
    curEvening = null;
  }

  void setDailyRoutine({required int timeOfDay, Routine? routine}) {
    if (null == routine) {
      return;
    }
    if (timeOfDay & 1 == 1) {
      curMorning = routine;
    }
    if (timeOfDay & 2 == 2) {
      curAfternoon = routine;
    }
    if (timeOfDay & 4 == 4) {
      curEvening = routine;
    }
    if (timeOfDay == 0) {
      unsetDailyRoutine(id: routine.id);
    }
  }

  void unsetDailyRoutine({required int id}) {
    if (id == curMorning?.id) {
      curMorning = null;
    }
    if (id == curAfternoon?.id) {
      curAfternoon = null;
    }
    if (id == curEvening?.id) {
      curEvening = null;
    }
  }

  int get routineWeight =>
      (curMorning?.weight ?? 0) +
      (curAfternoon?.weight ?? 0) +
      (curEvening?.weight ?? 0);

  List<Routine> routines = [];

  late RoutineSorter sorter;

  void startTimer() {
    syncTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (user?.syncOnline ?? false) {
        _syncRepo();
      } else {
        _routineService.clearDeletesLocalRepo();
      }
    });
  }

  void setUser({User? user}) {
    user = user;
    sorter = user?.routineSorter ?? sorter;
    setDailyRoutines();
  }

  int getRoutineTime({Routine? routine}) {
    int times = 0;
    if (_curMorning == routine) {
      times |= 1;
    }
    if (_curAfternoon == routine) {
      times |= 2;
    }
    if (_curEvening == routine) {
      times |= 4;
    }
    return times;
  }

  Future<void> setDailyRoutines() async {
    curMorning = (null != user?.curMornID!)
        ? await _routineService.getRoutineByID(id: user!.curMornID!)
        : null;

    curAfternoon = (null != user?.curAftID!)
        ? await _routineService.getRoutineByID(id: user!.curAftID!)
        : null;

    curEvening = (null != user?.curAftID!)
        ? await _routineService.getRoutineByID(id: user!.curAftID!)
        : null;
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
    user?.routineSorter = sorter;
    notifyListeners();
  }

  bool get descending => sorter.descending;

  List<SortMethod> get sortMethods => sorter.sortMethods;

  Future<void> recalculateWeight() async {
    _routineService.recalculateWeight(routine: curRoutine!);
    await updateRoutine();
  }

  Future<void> recalculateRealDuration() async {
    _routineService.setRealDuration(routine: curRoutine!);
    await updateRoutine();
  }

  int calculateRealDuration({int? weight, int? duration}) =>
      _routineService.calculateRealDuration(weight: weight, duration: duration);

  Future<int> getWeight(
          {required int taskID, int limit = Constants.maxNumTasks}) async =>
      await _subtaskService.getTaskSubtaskWeight(taskID: taskID, limit: limit);

  // int calculateWeight({List<Subtask>? routineTasks}) =>
  //     _routineService.calculateWeight(routineTasks: routineTasks);

  ValueNotifier<int> getSubtaskCount(
      {required int id, int limit = Constants.maxNumTasks}) {
    if (routineSubtaskCounts.containsKey(id)) {
      return routineSubtaskCounts[id]!;
    }

    routineSubtaskCounts[id] = ValueNotifier<int>(0);
    setSubtaskCount(id: id, limit: limit);
    return routineSubtaskCounts[id]!;
  }

  Future<void> setSubtaskCount(
      {required int id, int limit = Constants.maxNumTasks}) async {
    int count =
        await _subtaskService.getTaskSubtasksCount(taskID: id, limit: limit);
    if (routineSubtaskCounts.containsKey(id)) {
      routineSubtaskCounts[id]?.value = count;
    } else {
      routineSubtaskCounts[id] = ValueNotifier<int>(count);
    }
  }

  Future<void> _syncRepo() async {
    // Not quite sure how to handle this outside of gui warning.
    try {
      await _routineService.syncRepo();
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      log("This is a fatal error.");
    } on FailureToUploadException catch (e) {
      log(e.cause);
      log("This is a fatal error, supabase issue");
    }
    notifyListeners();
  }

  // Refactor this please.
  Future<void> createRoutine({
    required String name,
    int? expectedDuration,
    int? realDuration,
    int? weight,
    int? times,
    List<Subtask>? subtasks,
  }) async {
    times = times ?? 0;
    subtasks =
        subtasks ?? await _subtaskService.getTaskSubtasks(id: Constants.intMax);
    weight = weight ?? await getWeight(taskID: Constants.intMax);
    expectedDuration = expectedDuration ?? (const Duration(hours: 1)).inSeconds;
    realDuration = realDuration ??
        _routineService.calculateRealDuration(
            weight: weight, duration: expectedDuration);

    curRoutine = Routine(
        name: name,
        weight: weight,
        expectedDuration: expectedDuration,
        realDuration: realDuration,
        subtasks: subtasks,
        lastUpdated: DateTime.now());

    try {
      curRoutine = await _routineService.createRoutine(routine: curRoutine!);
    } on FailureToCreateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      curRoutine!.isSynced = false;
      return updateRoutine();
    }

    await _updateSubtasks(subtasks: subtasks, taskID: curRoutine!.id);
    routineSubtaskCounts[Constants.intMax]!.value = 0;
    setDailyRoutine(timeOfDay: times, routine: curRoutine);
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

  Future<void> updateRoutine({Routine? routine, int? times}) async {
    routine = routine ?? curRoutine;
    await updateRoutineAsync(routine: routine);
    if (null != times) {
      setDailyRoutine(timeOfDay: times, routine: routine);
    }
    notifyListeners();
  }

  Future<void> updateRoutineAsync({Routine? routine}) async {
    routine = routine ?? curRoutine!;
    routine.lastUpdated = DateTime.now();

    try {
      curRoutine = await _routineService.updateRoutine(routine: routine);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<void> updateBatch({List<Routine>? routines}) async {
    routines = routines ?? this.routines;
    for (Routine routine in routines) {
      routine.lastUpdated = DateTime.now();
    }
    try {
      await _routineService.updateBatch(routines: routines);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    notifyListeners();
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

    // This eliminates empty subtasks.
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

  Future<void> deleteRoutine({Routine? routine}) async {
    routine = routine ?? curRoutine!;
    try {
      await _routineService.deleteRoutine(routine: routine);
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

  Future<List<Routine>> reorderRoutines(
      {List<Routine>? routines,
      required int oldIndex,
      required int newIndex}) async {
    try {
      return await _routineService.reorderRoutines(
          routines: routines ?? this.routines,
          oldIndex: oldIndex,
          newIndex: newIndex);
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

  Future<void> resetRoutineSubtasks({Routine? routine}) async {
    routine = routine ?? curRoutine;
    try {
      await _subtaskService.resetSubtasks(id: routine!.id);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  // This is to be called once per day after midnight;
  Future<void> resetDailyRoutines() async {
    if (null != curMorning) {
      resetRoutineSubtasks(routine: curMorning);
    }
    if (null != curAfternoon) {
      resetRoutineSubtasks(routine: curAfternoon);
    }
    if (null != curEvening) {
      resetRoutineSubtasks(routine: curEvening);
    }
    notifyListeners();
  }

  Future<List<Routine>> getRoutines({int limit = 50, int offset = 0}) async =>
      await _routineService.getRoutines(limit: limit, offset: offset);

  Future<List<Subtask>> getSubtasks({
    required int id,
    limit = Constants.maxNumTasks,
  }) async =>
      await _subtaskService.getTaskSubtasks(id: id, limit: limit);

  Future<void> setRoutineList({int limit = 50, int offset = 0}) async =>
      await _routineService.getRoutines(limit: limit, offset: offset);

  Future<List<Routine>> getRoutinesBy({int limit = 50, int offset = 0}) async =>
      await _routineService.getRoutinesBy(
          routineSorter: sorter, limit: limit, offset: offset);

  Future<void> setRoutineListBy({int limit = 50, int offset = 0}) async =>
      await _routineService.getRoutinesBy(
          routineSorter: sorter, limit: limit, offset: offset);

  Future<List<Routine>> searchRoutines({required String searchString}) async =>
      await _routineService.searchRoutines(searchString: searchString);

  Future<List<Routine>> mostRecent({int limit = 5}) async =>
      await _routineService.mostRecent(limit: 5);

  Future<Routine?> getRoutineByID({int? id}) async =>
      await _routineService.getRoutineByID(id: id);

  Future<void> setRoutineByID({required int id}) async =>
      curRoutine = await _routineService.getRoutineByID(id: id) ??
          Routine(
              name: '',
              expectedDuration: 0,
              realDuration: 0,
              subtasks: List.filled(
                  Constants.maxNumTasks, Subtask(lastUpdated: DateTime.now())),
              lastUpdated: DateTime.now());
}
