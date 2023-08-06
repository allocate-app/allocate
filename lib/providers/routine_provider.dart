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

/// NOTE: For UI stuff:
/// In the form-input page class, declare local variables to hold each of the fields required.
/// Send those as arguments to the Provider method after validating.
///
/// also: FUTURE BUILDER will be required for UI stuff.

class RoutineProvider extends ChangeNotifier {
  late Timer syncTimer;

  final RoutineService _routineService;

  User? user;
  late Routine curRoutine;

  Routine? curMorning;
  Routine? curAfternoon;
  Routine? curEvening;

  late RoutineTime _timeOfDay;

  late List<Routine> routines;

  late RoutineSorter sorter;

  // This should initialize the morning/afternoon/evening routines.
  RoutineProvider({this.user, RoutineService? service})
      : _routineService = service ?? RoutineService() {
    sorter = user?.routineSorter ?? RoutineSorter();
  }

  Future<void> init() async {
    await setRoutines();
    startTimer();
  }

  int get routineWeight =>
      (curMorning?.weight ?? 0) +
      (curAfternoon?.weight ?? 0) +
      (curEvening?.weight ?? 0);

  void startTimer() {
    syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
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
    _routineService.recalculateWeight(routine: curRoutine);
    updateRoutine();
  }

  Future<void> recalculateRealDuration() async {
    _routineService.setRealDuration(routine: curRoutine);
    updateRoutine();
  }

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
      required timeOfDay,
      Duration? duration,
      int? weight,
      List<SubTask>? routineTasks}) async {
    routineTasks =
        (null != routineTasks && routineTasks.length == Constants.maxNumTasks)
            ? routineTasks
            : List.filled(Constants.maxNumTasks, SubTask());

    weight =
        weight ?? _routineService.calculateWeight(routineTasks: routineTasks);

    int expectedDuration =
        duration?.inSeconds ?? (const Duration(hours: 1)).inSeconds;
    int realDuration = _routineService.calculateRealDuration(
        weight: weight, duration: expectedDuration);

    curRoutine = Routine(
        routineTime: timeOfDay,
        name: name,
        weight: weight,
        expectedDuration: expectedDuration,
        realDuration: realDuration,
        routineTasks: routineTasks);

    try {
      _routineService.createRoutine(routine: curRoutine);
    } on FailureToCreateException catch (e) {
      log(e.cause);
      rethrow;
    } on FailureToUploadException catch (e) {
      log(e.cause);
      curRoutine.isSynced = false;
      return updateRoutine();
    }
    notifyListeners();
  }

  Future<void> updateRoutine() async {
    _routineService.recalculateWeight(routine: curRoutine);
    _routineService.setRealDuration(routine: curRoutine);
    try {
      _routineService.updateRoutine(routine: curRoutine);
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
      _routineService.deleteRoutine(routine: curRoutine);
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      rethrow;
    }
    notifyListeners();
  }

  Future<void> reorderRoutines(
      {required List<Routine> routines,
      required int oldIndex,
      required int newIndex}) async {
    try {
      _routineService.reorderRoutines(
          routines: routines, oldIndex: oldIndex, newIndex: newIndex);
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
    try {
      _routineService.resetRoutine(routine: curRoutine);
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
    try {
      _routineService
          .resetRoutines(routines: [curMorning, curAfternoon, curEvening]);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      rethrow;
    }
    notifyListeners();
  }

  Future<void> getRoutines() async =>
      _routineService.getRoutines(timeOfDay: _timeOfDay);
  Future<void> getRoutinesBy() async => _routineService.getRoutinesBy(
      timeOfDay: _timeOfDay, routineSorter: sorter);

  Future<void> getRoutineByID({required int id}) async =>
      curRoutine = await _routineService.getRoutineById(id: id) ??
          Routine(
              routineTime: RoutineTime.morning,
              name: '',
              expectedDuration: 0,
              realDuration: 0,
              routineTasks: List.filled(Constants.maxNumTasks, SubTask()));
}
