import 'dart:developer';

import 'package:flutter/foundation.dart';

import "../model/task/routine.dart";
import '../model/task/subtask.dart';
import '../services/routine_service.dart';
import '../util/enums.dart';
import "../util/exceptions.dart";
import '../util/sorting/routine_sorter.dart';

/// NOTE: For UI stuff:
/// In the form-input page class, declare local variables to hold each of the fields required.
/// Send those as arguments to the Provider method after validating.
///
/// also: FUTURE BUILDER will be required for UI stuff.

class RoutineProvider extends ChangeNotifier {
  // This should initialize the morning/afternoon/evening routines.
  RoutineProvider();

  // This may eventually be implemented as DI. Atm, no need to decouple.
  final RoutineService _routineService = RoutineService();

  late Routine curRoutine;

  /// TODO: refactor into user class to hold ids.
  Routine? _curMorning;
  Routine? _curAfternoon;
  Routine? _curEvening;

  late RoutineTime _timeOfDay;

  late List<Routine> routines;

  List<Routine> failCache = List.empty(growable: true);

  RoutineSorter sorter = RoutineSorter();

  Routine? get curMorning => _curMorning;
  set curMorning(Routine? newMorn) {
    if (null != _curMorning) {
      _resetRoutine(routine: _curMorning!);
    }
    _curMorning = newMorn;
    notifyListeners();
  }

  Routine? get curAfternoon => _curAfternoon;
  set curAfternoon(Routine? newAft) {
    if (null != _curAfternoon) {
      _resetRoutine(routine: _curAfternoon!);
    }
    _curAfternoon = newAft;
    notifyListeners();
  }

  Routine? get curEvening => _curEvening;
  set curEvening(Routine? newEve) {
    if (null != _curEvening) {
      _resetRoutine(routine: _curEvening!);
    }
    _curEvening = newEve;
    notifyListeners();
  }

  RoutineTime get timeOfDay => _timeOfDay;
  set timeOfDay(RoutineTime time) {
    _timeOfDay = time;
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

  List<SortMethod> get sortMethods => RoutineSorter.sortMethods;

  Future<void> recalculateWeight() async {
    _routineService.recalculateWeight(routine: curRoutine);
    updateRoutine();
  }

  Future<void> recalculateRealDuration() async {
    _routineService.setRealDuration(routine: curRoutine);
    updateRoutine();
  }

  Future<void> createRoutine(
      {required String name,
      required timeOfDay,
      Duration? duration,
      int? weight,
      List<SubTask>? routineTasks}) async {
    weight =
        weight ?? _routineService.calculateWeight(routineTasks: routineTasks);

    int expectedDuration =
        duration?.inSeconds ?? (const Duration(hours: 1)).inSeconds;
    int realDuration = _routineService.calculateRealDuration(
            weight: weight, duration: expectedDuration) ??
        0;

    curRoutine = Routine(
        routineTime: timeOfDay,
        name: name,
        weight: weight,
        expectedDuration: expectedDuration,
        realDuration: realDuration,
        routineTasks: routineTasks ?? List.empty(growable: true));

    try {
      _routineService.createRoutine(routine: curRoutine);
    } on FailureToCreateException catch (e) {
      log(e.cause);
      failCache.add(curRoutine);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      failCache.add(curRoutine);
      return;
    }

    notifyListeners();
  }

  // TODO: this may actually be best removed, or refactored
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

  Future<void> updateRoutineTask(
      {required SubTask routineTask,
      String? name,
      int? weight,
      bool? completed}) async {
    SubTask newRoutineTask = routineTask.copyWith(name: name, weight: weight);
    newRoutineTask.completed = completed ?? routineTask.completed;

    try {
      _routineService.updateRoutineTask(
          oldTask: routineTask, newTask: newRoutineTask, routine: curRoutine);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      failCache.add(curRoutine);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      failCache.add(curRoutine);
    }
    notifyListeners();
  }

  Future<void> deleteRoutineTask({required SubTask routineTask}) async {
    try {
      _routineService.deleteRoutineTask(
          routineTask: routineTask, routine: curRoutine);
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
      Duration? duration,
      List<SubTask>? routineTasks}) async {
    int? expectedDuration = duration?.inSeconds;
    int? realDuration = (null == expectedDuration)
        ? null
        : _routineService.calculateRealDuration(
            weight: weight ?? curRoutine.weight, duration: expectedDuration);
    Routine routine = curRoutine.copyWith(
        routineTime: routineTime,
        name: name,
        weight: weight,
        expectedDuration: expectedDuration,
        realDuration: realDuration,
        routineTasks: routineTasks);

    if (routine.weight == 0 && routine.routineTasks.isNotEmpty) {
      _routineService.recalculateWeight(routine: routine);
    }
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

  // Future<void> _updateBatch({required List<Routine> routines}) async {
  //   try {
  //     _routineService.updateBatch(routines: routines);
  //   } on FailureToUploadException catch (e) {
  //     log(e.cause);
  //     failCache.addAll(routines);
  //   } on FailureToUpdateException catch (e) {
  //     log(e.cause);
  //     failCache.addAll(routines);
  //   }
  // }

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
      failCache.addAll(routines);
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
      failCache.add(curRoutine);
    }
    notifyListeners();
  }

  Future<void> _resetRoutine({required Routine routine}) async {
    try {
      _routineService.resetRoutine(routine: routine);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      failCache.add(routine);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      failCache.add(routine);
    }
  }

  // This is to be called once per day after midnight;
  Future<void> resetRoutines() async {
    try {
      _routineService
          .resetRoutines(routines: [_curMorning, _curAfternoon, _curEvening]);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      if (null != _curMorning) {
        failCache.add(_curMorning!);
      }
      if (null != _curAfternoon) {
        failCache.add(_curAfternoon!);
      }
      if (null != _curEvening) {
        failCache.add(_curEvening!);
      }
    } on FailureToUploadException catch (e) {
      log(e.cause);
      if (null != _curMorning) {
        failCache.add(_curMorning!);
      }
      if (null != _curAfternoon) {
        failCache.add(_curAfternoon!);
      }
      if (null != _curEvening) {
        failCache.add(_curEvening!);
      }
    }
    notifyListeners();
  }

  Future<void> getRoutines() async =>
      _routineService.getRoutines(timeOfDay: _timeOfDay);
  Future<void> getRoutinesBy() async => _routineService.getRoutinesBy(
      timeOfDay: _timeOfDay, routineSorter: sorter);
}
