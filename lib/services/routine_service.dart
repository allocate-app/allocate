import 'package:allocate/util/exceptions.dart';

import '../model/task/routine.dart';
import '../model/task/subtask.dart';
import '../repositories/routine_repo.dart';
import '../util/enums.dart';
import '../util/interfaces/repository/routine_repository.dart';
import '../util/interfaces/sorting/sortable.dart';
import '../util/numbers.dart';

class RoutineService {
  RoutineService();
  // May need to construct this with the repository...?
  /// TODO: Periodic function to reset subtask complete status.
  /// Until/if subtasks are refactored into their own table.

  // This is just the default repo. Switch as needed for testing.
  RoutineRepository _repository = RoutineRepo();

  set repository(RoutineRepository repo) => _repository = repo;

  int recalculateWeight({List<SubTask>? routineTasks}) {
    if (null == routineTasks || routineTasks.isEmpty) {
      return 0;
    }
    return routineTasks.fold(0, (p, c) => p + c.weight);
  }

  int getRealDuration({required int seconds, required int weight}) =>
      (smoothstep(x: weight, v0: Routine.lowerBound, v1: Routine.upperBound) *
          seconds) as int;

  Future<void> createRoutine({required Routine routine}) async =>
      _repository.create(routine);

  Future<List<Routine>> getRoutines(
          {RoutineTime timeOfDay = RoutineTime.morning}) async =>
      _repository.getRepoList();
  Future<List<Routine>> getRoutinesBy(
          {RoutineTime timeOfDay = RoutineTime.morning,
          required SortableView<Routine> routineSorter}) async =>
      _repository.getRepoListBy(sorter: routineSorter);

  Future<void> updateRoutine({required Routine routine}) async {
    routine.realDuration = getRealDuration(
        seconds: routine.expectedDuration, weight: routine.weight);
    return _repository.update(routine);
  }

  Future<void> updateBatch({required List<Routine> routines}) async =>
      _repository.updateBatch(routines);

  Future<void> deleteRoutine({required Routine routine}) async =>
      _repository.delete(routine);

  Future<void> retry({required List<Routine> routines}) async =>
      _repository.retry(routines);
  // TODO: Figure out how to call this on a timer.
  Future<void> syncRepo() async => _repository.syncRepo();

  Future<void> addRoutineTask(
      {required SubTask subTask, required Routine routine}) async {
    if (routine.routineTasks.length >= Routine.maxTasksPerRoutine) {
      throw ListLimitExceededException("Routine limit exceeded");
    }

    routine.routineTasks.add(subTask);
    routine.weight += routine.weight;
    updateRoutine(routine: routine);
  }

  Future<void> updateRoutineTask(
      {required int oldWeight,
      required index,
      required SubTask routineTask,
      required Routine routine}) async {
    routine.routineTasks[index] = routineTask;
    routine.weight += (-oldWeight) + routineTask.weight;

    if (routine.weight < 0) {
      routine.weight = 0;
    }

    updateRoutine(routine: routine);
  }

  Future<void> deleteRoutineTask(
      {required SubTask routineTask, required Routine routine}) async {
    bool removed = routine.routineTasks.remove(routineTask);
    if (removed) {
      routine.weight -= routineTask.weight;
    }
    updateRoutine(routine: routine);
  }

  Future<void> reorderRoutineTask(
      {required Routine routine,
      required int oldIndex,
      required int newIndex}) async {
    if (oldIndex < newIndex) {
      newIndex--;
    }
    SubTask st = routine.routineTasks.removeAt(oldIndex);
    routine.routineTasks.insert(newIndex, st);
    updateRoutine(routine: routine);
  }

  Future<void> reorderRoutines(
      {required List<Routine> routines,
      required int oldIndex,
      required int newIndex}) async {
    if (oldIndex < newIndex) {
      newIndex--;
    }
    Routine routine = routines.removeAt(oldIndex);
    routines.insert(newIndex, routine);
    for (int i = 0; i < routines.length; i++) {
      routines[i].customViewIndex = i;
    }
    _repository.updateBatch(routines);
  }
}
