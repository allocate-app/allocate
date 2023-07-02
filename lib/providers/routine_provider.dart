import 'dart:developer';
import 'package:allocate/providers/routine_datacache.dart';
import 'package:flutter/foundation.dart';
import '../model/task/subtask.dart';
import '../services/routine_service.dart';
import "../model/task/routine.dart";
import '../util/enums.dart';
import "../util/exceptions.dart";
import '../util/interfaces/datacache.dart';
import '../util/sorters/routine_sorter.dart';

// Providers are singletons.
class RoutineProvider extends ChangeNotifier {
  static final RoutineProvider _instance = RoutineProvider._internal();
  static RoutineProvider get instance => _instance;

  // This could be switched out for DI. Right now, singleton.
  final RoutineService _routineService = RoutineService.instance;

  DataCache<Routine> dataCache = RoutineDataCache.instance;

  Routine get curRoutine => dataCache.current;
  set curRoutine(Routine r) => dataCache.current = r;

  List<Routine> get routines => dataCache.currents;
  set routines(List<Routine> newRoutines) => dataCache.currents = newRoutines;

  List<Routine> get failCache => dataCache.cache;
  RoutineSortable sorter = RoutineSorter();

  set timeOfDay(RoutineTime time)
  {
    sorter.timeOfDay = time;
    notifyListeners();
  }


  SortMethod get curSortMethod => sorter.sortMethod;
  set curSortMethod(SortMethod method) {
    if (method == sorter.sortMethod) {
      sorter.descending = !sorter.descending;
      return;
    }
    sorter.sortMethod = method;
    notifyListeners();
  }

  bool get descending => sorter.descending;
  List<SortMethod> get sortMethods => sorter.sortMethods;

  // ref.watch(RoutineProvider).

  Future<void> createRoutine(Routine r) async {
    // Possibly create the routine => here.
    // Accept args from text val.
    try {
      _routineService.createRoutine(r);
    } on FailureToCreateException catch (e) {
      log(e.cause);
      r.isSynced = false;
      failCache.add(r);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      failCache.add(r);
    }

    // Some sort of success widget & move to edit view mb?
    notifyListeners();
  }
  // Possibly refactor this so that it takes args instead of an object.
  Future<void> addRoutineTask(SubTask st) async
  {
    try{
      _routineService.addRoutineTask(st, curRoutine);
    }
    on ListLimitExceededException catch(e)
    {
      log(e.cause);
      // Throw some GUI error or something.
    }
    notifyListeners();
  }

  Future<void> updateRoutineTask (int oldWeight, int newWeight) async
  {
    try{
      _routineService.updateRoutineTask(oldWeight, newWeight, curRoutine);
    }
    on FailureToUpdateException catch (e)
    {
      log(e.cause);
      failCache.add(curRoutine);
    }
    on FailureToUploadException catch (e)
    {
      log(e.cause);
      failCache.add(curRoutine);
    }
    notifyListeners();
  }

  Future<void> deleteRoutineTask(SubTask st) async
  {
    try{
      _routineService.deleteRoutineTask(st, curRoutine);
    }
    on FailureToUpdateException catch (e)
    {
      log(e.cause);
      failCache.add(curRoutine);
    }
    on FailureToUploadException catch (e){
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
    Routine rt = curRoutine.copyWith(
        routineTime: routineTime,
        name: name,
        weight: weight,
        expectedDuration: expectedDuration,
        routineTasks: routineTasks);
    rt.id = curRoutine.id;
    try {
      _routineService.updateRoutine(rt);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      failCache.add(rt);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      failCache.add(rt);
    }
    notifyListeners();
  }


  Future<void> _updateBatch(List<Routine> routines) async {
    try {
      _routineService.updateBatch(routines);
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
      _routineService.retry(failCache);
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
      _routineService.updateRoutine(curRoutine);
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      failCache.add(curRoutine);
    }
    notifyListeners();
  }

  Future<void> reorderRoutines(
      List<Routine> routines, int oldIndex, int newIndex) async {
    try {
      _routineService.reorderRoutines(routines, oldIndex, newIndex);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      failCache.addAll(routines);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      // Re-store into local database, on total failure, cache.
      _updateBatch(routines);
    }
    notifyListeners();
  }

  // This should be void and update the data cache.
  // Consider refactoring getRoutinesBy into just getRoutines with default arg.
  Future<void> getRoutines() async {
    routines = await _routineService.getRoutines();
    notifyListeners();
  }

  Future<void> getRoutinesBy() async {
    routines = await _routineService.getRoutinesBy(routineSorter: sorter);
    notifyListeners();
  }

  Future<void> recalculateWeight() async {
    try
        {
          _routineService.recalculateWeight(curRoutine);
        }
    on FailureToUploadException catch (e)
    {
      log(e.cause);
      failCache.add(curRoutine);
    }
    on FailureToUpdateException catch (e){
      log(e.cause);
      failCache.add(curRoutine);
    }

    notifyListeners();
  }

  RoutineProvider._internal();
}
