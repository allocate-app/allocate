import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import "../model/task/routine.dart";
import '../model/task/subtask.dart';
import '../model/user/user.dart';
import '../services/routine_service.dart';
import '../util/constants.dart';
import '../util/enums.dart';
import "../util/exceptions.dart";
import '../util/sorting/routine_sorter.dart';

class RoutineProvider extends ChangeNotifier {
  late Timer syncTimer;

  final RoutineService _routineService;

  User? user;
  Routine? curRoutine;

  Routine? curMorning;
  Routine? curAfternoon;
  Routine? curEvening;

  late List<Routine> routines;

  late RoutineSorter sorter;

  // This should initialize the morning/afternoon/evening routines.
  RoutineProvider({this.user, RoutineService? service})
      : _routineService = service ?? RoutineService() {
    sorter = user?.routineSorter ?? RoutineSorter();
    init();
  }

  Future<void> init() async {
    await setRoutines();
    startTimer();
  }

  int get routineWeight =>
      (curMorning?.weight ?? 0) + (curAfternoon?.weight ?? 0) + (curEvening?.weight ?? 0);

  void startTimer() {
    print("syncTimer is being initialized");
    syncTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (user?.syncOnline ?? false) {
        print("Routine Timer is calling");
        _syncRepo();
      } else {
        print("Routine Timer Is Going");
        _routineService.clearDeletesLocalRepo();
      }
    });
  }

  void setUser({User? user}) {
    user = user;
    sorter = user?.routineSorter ?? sorter;
    setRoutines();
  }

  // Call this in a future builder for the routines screen.
  Future<void> setRoutines() async {
    curMorning = (null != user?.curMornID!)
        ? await _routineService.getRoutineById(id: user!.curMornID!)
        : null;

    curAfternoon = (null != user?.curAftID!)
        ? await _routineService.getRoutineById(id: user!.curAftID!)
        : null;

    curEvening = (null != user?.curAftID!)
        ? await _routineService.getRoutineById(id: user!.curAftID!)
        : null;
    notifyListeners();
  }

  SortMethod get sortMethod => sorter.sortMethod;

  // This will likely need refactoring once gui.
  // Sort method logic are all part of the user.
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

  List<SortMethod> get sortMethods => RoutineSorter.sortMethods;

  Future<void> recalculateWeight() async {
    _routineService.recalculateWeight(routine: curRoutine!);
    updateRoutine();
  }

  Future<void> recalculateRealDuration() async {
    _routineService.setRealDuration(routine: curRoutine!);
    updateRoutine();
  }

  int calculateRealDuration({int? weight, int? duration}) =>
      _routineService.calculateRealDuration(weight: weight, duration: duration);
  int calculateWeight({List<SubTask>? routineTasks}) =>
      _routineService.calculateWeight(routineTasks: routineTasks);

  Future<void> _syncRepo() async {
    // Not quite sure how to handle this outside of gui warning.
    try {
      _routineService.syncRepo();
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      log("This is a fatal error.");
    } on FailureToUploadException catch (e) {
      log(e.cause);
      log("This is a fatal error, supabase issue");
    }
    notifyListeners();
  }

  // Subtasks are fixed-length.
  Future<void> createRoutine(
      {required String name,
      int? expectedDuration,
      int? realDuration,
      int? weight,
      List<SubTask>? routineTasks}) async {

    routineTasks = (null != routineTasks && routineTasks.length == Constants.maxNumTasks)
        ? routineTasks
        : List.filled(Constants.maxNumTasks, SubTask());

    weight = weight ?? _routineService.calculateWeight(routineTasks: routineTasks);

    expectedDuration = expectedDuration ?? (const Duration(hours: 1)).inSeconds;
    realDuration = realDuration ??
        _routineService.calculateRealDuration(weight: weight, duration: expectedDuration);

    curRoutine = Routine(
        name: name,
        weight: weight,
        expectedDuration: expectedDuration,
        realDuration: realDuration,
        routineTasks: routineTasks,
        lastUpdated: DateTime.now());

    curRoutine!.localID = curRoutine!.hashCode;

    try {
      _routineService.createRoutine(routine: curRoutine!);
    } on FailureToCreateException catch (e) {
      log(e.cause);
      rethrow;
    } on FailureToUploadException catch (e) {
      log(e.cause);
      curRoutine!.isSynced = false;
      return updateRoutine();
    }
    notifyListeners();
  }

  Future<void> updateRoutine() async {

    curRoutine!.lastUpdated = DateTime.now();

    try {
      _routineService.updateRoutine(routine: curRoutine!);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      rethrow;
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      rethrow;
    }
    notifyListeners();
  }

  Future<void> deleteRoutine() async {
    try {
      _routineService.deleteRoutine(routine: curRoutine!);
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      rethrow;
    }
    notifyListeners();
  }

  Future<void> reorderRoutines(
      {required List<Routine> routines, required int oldIndex, required int newIndex}) async {
    try {
      _routineService.reorderRoutines(routines: routines, oldIndex: oldIndex, newIndex: newIndex);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      rethrow;
    } on FailureToUploadException catch (e) {
      log(e.cause);
      rethrow;
    }
    notifyListeners();
  }

  Future<void> resetRoutine() async {
    curRoutine!.lastUpdated = DateTime.now();
    try {
      _routineService.resetRoutine(routine: curRoutine!);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      rethrow;
    } on FailureToUploadException catch (e) {
      log(e.cause);
      rethrow;
    }
  }

  // This is to be called once per day after midnight;
  Future<void> resetRoutines() async {
    curMorning?.lastUpdated = DateTime.now();
    curAfternoon?.lastUpdated = DateTime.now();
    curEvening?.lastUpdated = DateTime.now();
    try {
      _routineService.resetRoutines(routines: [curMorning, curAfternoon, curEvening]);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      rethrow;
    }
    notifyListeners();
  }

  Future<List<Routine>> getRoutines({int limit = 50, int offset = 0}) async =>
      _routineService.getRoutines(limit: limit, offset: offset);

  Future<void> setRoutineList({int limit = 50, int offset = 0}) async =>
      _routineService.getRoutines(limit: limit, offset: offset);

  Future<List<Routine>> getRoutinesBy({int limit = 50, int offset = 0}) async =>
      _routineService.getRoutinesBy(routineSorter: sorter, limit: limit, offset: offset);

  Future<void> setRoutineListBy({int limit = 50, int offset = 0}) async =>
      _routineService.getRoutinesBy(routineSorter: sorter, limit: limit, offset: offset);

  Future<List<Routine>> searchRoutines({required String searchString}) async =>
      _routineService.searchRoutines(searchString: searchString);

  Future<List<Routine>> mostRecent({int limit = 5}) async =>
      await _routineService.mostRecent(limit: 5);

  Future<Routine?> getRoutineByID({required int id}) async =>
      await _routineService.getRoutineById(id: id);

  Future<void> setRoutineByID({required int id}) async =>
      curRoutine = await _routineService.getRoutineById(id: id) ??
          Routine(
              name: '',
              expectedDuration: 0,
              realDuration: 0,
              routineTasks: List.filled(Constants.maxNumTasks, SubTask()),
              lastUpdated: DateTime.now());
}
