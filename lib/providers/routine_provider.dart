import 'dart:developer';

import 'package:flutter/foundation.dart';

import "../model/task/routine.dart";
import '../model/task/subtask.dart';
import '../services/routine_service.dart';
import '../util/enums.dart';
import "../util/exceptions.dart";
import '../util/interfaces/sorting/routine_sorter.dart';

/// NOTE: For UI stuff:
/// In the form-input page class, declare local variables to hold each of the fields required.
/// Send those as arguments to the Provider method after validating.
///
/// also: FUTURE BUILDER will be required for UI stuff.

class RoutineProvider extends ChangeNotifier {
  RoutineProvider();

  // This may eventually be implemented as DI. Atm, no need to decouple.
  final RoutineService _routineService = RoutineService();

  // Cache stuff.
  late Routine curRoutine;

  /// TODO: refactor into user class.
  late Routine curMorning;
  late Routine curAfternoon;
  late Routine curEvening;

  late List<Routine> mornings;
  late List<Routine> afternoons;
  late List<Routine> evenings;

  List<Routine> failCache = List.empty(growable: true);

  RoutineSorter sorter = RoutineSorter();

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

  List<SortMethod> get sortMethods => RoutineSorter.sortMethods;

  int recalculateWeight({List<SubTask>? routineTasks}) =>
      _routineService.recalculateWeight(routineTasks: routineTasks);

  // Future<void> init() async
  // {
  //   /// TODO:
  //   /// figure out User shared preferences for sortmethods.
  // }

  Future<void> createRoutine(
      {required String name,
      required timeOfDay,
      List<SubTask>? routineTasks}) async {
    curRoutine = Routine(
        routineTime: timeOfDay,
        name: name,
        weight: _routineService.recalculateWeight(routineTasks: routineTasks),
        routineTasks: routineTasks);
    try {
      _routineService.createRoutine(routine: curRoutine);
    } on FailureToCreateException catch (e) {
      log(e.cause);
      failCache.add(curRoutine);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      updateRoutine();
      return;
    }

    notifyListeners();
  }

  // Possibly refactor this so that it takes args instead of an object.
  Future<void> addRoutineTask({required String name, int? weight}) async {
    SubTask routineTask = SubTask(name: name, weight: weight ?? 0);
    try {
      _routineService.addRoutineTask(subTask: routineTask, routine: curRoutine);
      //_routine
    } on ListLimitExceededException catch (e) {
      log(e.cause);
      // Throw some GUI error or something.
    }
    notifyListeners();
  }

  Future<void> updateRoutineTask({
    required SubTask routineTask,
    String? name,
    int? weight,
    bool? completed,
  }) async {
    // TODO: figure out whether this can be grabbed via gui.
    int index = curRoutine.routineTasks.indexOf(routineTask);
    int oldWeight = routineTask.weight;
    SubTask newRoutineTask = routineTask.copyWith(name: name, weight: weight);
    newRoutineTask.completed = completed ?? routineTask.completed;

    try {
      _routineService.updateRoutineTask(
          oldWeight: oldWeight,
          index: index,
          routineTask: newRoutineTask,
          routine: curRoutine);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      failCache.add(curRoutine);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      updateRoutine();
    }
    notifyListeners();
  }

  Future<void> deleteRoutineTask({required SubTask subTask}) async {
    try {
      _routineService.deleteRoutineTask(
          routineTask: subTask, routine: curRoutine);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      failCache.add(curRoutine);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      failCache.add(curRoutine);
    }
    notifyListeners();
  }

  // This should just be args.
  Future<void> updateRoutine(
      {RoutineTime? routineTime,
      String? name,
      int? weight,
      Duration? expectedDuration,
      List<SubTask>? routineTasks}) async {
    Routine routine = curRoutine.copyWith(
        routineTime: routineTime,
        name: name,
        weight: weight,
        expectedDuration: expectedDuration,
        routineTasks: routineTasks);
    routine.id = curRoutine.id;
    routine.customViewIndex = curRoutine.customViewIndex;
    curRoutine = routine;
    try {
      _routineService.updateRoutine(routine: curRoutine);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      failCache.add(curRoutine);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      failCache.add(curRoutine);
    }
    notifyListeners();
  }

  Future<void> _updateBatch({required List<Routine> routines}) async {
    try {
      _routineService.updateBatch(routines: routines);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      failCache.addAll(routines);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      failCache.addAll(routines);
    }
  }

  // This should probably be privately called on a timer.
  // Possibly user function?
  Future<void> _reattemptUpdate() async {
    try {
      _routineService.retry(routines: failCache);
      failCache.clear();
    } on FailureToUploadException catch (e) {
      log("DataCache - ${e.cause}");
    } on FailureToUpdateException catch (e) {
      log("DataCache - ${e.cause}");
    }
    notifyListeners();
  }

  Future<void> deleteRoutine() async {
    try {
      _routineService.deleteRoutine(routine: curRoutine);
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      failCache.add(curRoutine);
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
      failCache.addAll(routines);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      // Re-store into local database, on total failure, cache.
      _updateBatch(routines: routines);
    }
    notifyListeners();
  }

  Future<void> reorderRoutineTask(
      {required int oldIndex, required int newIndex}) async {
    try {
      _routineService.reorderRoutineTask(
          routine: curRoutine, oldIndex: oldIndex, newIndex: newIndex);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      failCache.add(curRoutine);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      // Re-store into local database, on total failure, cache.
      updateRoutine();
    }
    notifyListeners();
  }

  Future<void> _resetComplete({required Routine routine}) async {
    routine.routineTasks.map((routineTask) => routineTask.completed = false);
    _routineService.updateRoutine(routine: routine);
  }

  Future<void> _resetAllCompletes() async {
    curMorning.routineTasks.map((routineTask) => routineTask.completed = false);
    curAfternoon.routineTasks
        .map((routineTask) => routineTask.completed = false);
    curEvening.routineTasks.map((routineTask) => routineTask.completed = false);

    _updateBatch(routines: [curMorning, curAfternoon, curEvening]);
  }

  Future<void> getMorningsBy() async {
    mornings = await _routineService.getRoutinesBy(
        timeOfDay: RoutineTime.morning, routineSorter: sorter);
    notifyListeners();
  }

  Future<void> getAftsBy() async {
    afternoons = await _routineService.getRoutinesBy(
        timeOfDay: RoutineTime.afternoon, routineSorter: sorter);
    notifyListeners();
  }

  Future<void> getEvesBy() async {
    evenings = await _routineService.getRoutinesBy(
        timeOfDay: RoutineTime.evening, routineSorter: sorter);
    notifyListeners();
  }

  // Not quite sure if this is necessary, but keeping for now for UI.
  Future<void> getAll() async {
    mornings = await _routineService.getRoutinesBy(
        timeOfDay: RoutineTime.morning, routineSorter: sorter);
    afternoons = await _routineService.getRoutinesBy(
        timeOfDay: RoutineTime.afternoon, routineSorter: sorter);
    evenings = await _routineService.getRoutinesBy(
        timeOfDay: RoutineTime.evening, routineSorter: sorter);
    notifyListeners();
  }
}
