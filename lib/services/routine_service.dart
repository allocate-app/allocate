import 'package:allocate/util/exceptions.dart';

import '../model/task/routine.dart';
import '../model/task/subtask.dart';
import '../repositories/routine_repo.dart';
import '../util/constants.dart';
import '../util/enums.dart';
import '../util/interfaces/repository/routine_repository.dart';
import '../util/interfaces/sortable.dart';
import '../util/numbers.dart';

class RoutineService {
  RoutineService();
  // May need to construct this with the repository...?
  /// TODO: Periodic function to reset subtask complete status.
  /// Until/if subtasks are refactored into their own table.

  // This is just the default repo. Switch as needed for testing.
  RoutineRepository _repository = RoutineRepo();

  set repository(RoutineRepository repo) => _repository = repo;

  int calculateWeight({List<SubTask>? routineTasks}) =>
      (routineTasks ?? List.empty(growable: false))
          .fold(0, (p, c) => p + c.weight);

  void recalculateWeight({required Routine routine}) {
    routine.weight = routine.routineTasks.fold(0, (p, c) => p + c.weight);
  }

  int calculateRealDuration({int? weight, int? duration}) => (remap(
          x: weight ?? 0,
          inMin: 0,
          inMax: Constants.maxWeight,
          outMin: Constants.lowerBound,
          outMax: Constants.upperBound) *
      (duration ?? 0)) as int;

  void setRealDuration({required Routine routine}) =>
      routine.realDuration = (remap(
              x: routine.weight,
              inMin: 0,
              inMax: Constants.maxWeight,
              outMin: Constants.lowerBound,
              outMax: Constants.upperBound) *
          routine.expectedDuration) as int;

  Future<void> createRoutine({required Routine routine}) async =>
      _repository.create(routine);

  Future<List<Routine>> getRoutines(
          {RoutineTime timeOfDay = RoutineTime.morning}) async =>
      _repository.getRepoList();
  Future<List<Routine>> getRoutinesBy(
          {RoutineTime timeOfDay = RoutineTime.morning,
          required SortableView<Routine> routineSorter}) async =>
      _repository.getRepoListBy(sorter: routineSorter);

  Future<Routine> getRoutineById({required int id}) async =>
      _repository.getByID(id: id);

  Future<void> updateRoutine({required Routine routine}) async =>
      _repository.update(routine);

  Future<void> updateBatch({required List<Routine> routines}) async =>
      _repository.updateBatch(routines);

  Future<void> deleteRoutine({required Routine routine}) async =>
      _repository.delete(routine);

  Future<void> retry({required List<Routine> routines}) async =>
      _repository.retry(routines);
  // TODO: Figure out how to call this on a timer.
  Future<void> syncRepo() async => _repository.syncRepo();

  // TODO: Refactor this -> Subtask editing should just handle subtask add/subtract.
  Future<void> addRoutineTask(
      {required SubTask subTask, required Routine routine}) async {
    if (routine.routineTasks.length >= Constants.maxNumTasks) {
      throw ListLimitExceededException("Routine limit exceeded");
    }

    routine.routineTasks.add(subTask);
    routine.weight += subTask.weight;
  }

  Future<void> updateRoutineTask(
      {required SubTask oldTask,
      required SubTask newTask,
      required Routine routine}) async {
    int index = routine.routineTasks.indexOf(oldTask);
    routine.weight += (-oldTask.weight) + newTask.weight;
    routine.routineTasks[index] = newTask;

    if (routine.weight < 0 && routine.routineTasks.isNotEmpty) {
      recalculateWeight(routine: routine);
    }
  }

  Future<void> deleteRoutineTask(
      {required SubTask routineTask, required Routine routine}) async {
    bool removed = routine.routineTasks.remove(routineTask);
    if (removed) {
      routine.weight -= routineTask.weight;
    }
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

  Future<void> resetRoutine({required Routine routine}) async {
    routine.routineTasks.map((rt) => rt.completed = false);
    updateRoutine(routine: routine);
  }

  Future<void> resetRoutines({required List<Routine?> routines}) async {
    List<Routine> toUpdate = List.empty(growable: true);
    for (Routine? routine in routines) {
      if (null != routine) {
        routine.routineTasks.map((rt) => rt.completed = false);
        toUpdate.add(routine);
      }
    }
    updateBatch(routines: toUpdate);
  }
}
