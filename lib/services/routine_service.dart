import '../model/task/routine.dart';
import '../model/task/subtask.dart';
import '../repositories/routine_repo.dart';
import '../util/constants.dart';
import '../util/interfaces/repository/model/routine_repository.dart';
import '../util/interfaces/sortable.dart';
import '../util/numbers.dart';

class RoutineService {
  // This is just the default repo. Switch as needed for testing.

  RoutineRepository _repository = RoutineRepo();

  set repository(RoutineRepository repo) => _repository = repo;

  int calculateWeight({List<SubTask>? routineTasks}) =>
      (routineTasks ?? List.empty(growable: false)).fold(0, (p, c) => p + c.weight);

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

  void setRealDuration({required Routine routine}) => routine.realDuration = (remap(
          x: routine.weight,
          inMin: 0,
          inMax: Constants.maxWeight,
          outMin: Constants.lowerBound,
          outMax: Constants.upperBound) *
      routine.expectedDuration) as int;

  Future<void> createRoutine({required Routine routine}) async => _repository.create(routine);

  Future<List<Routine>> searchRoutines({required String searchString}) async =>
      _repository.search(searchString: searchString);

  Future<List<Routine>> getRoutines({int limit = 50, int offset = 0}) async =>
      _repository.getRepoList(limit: limit, offset: offset);
  Future<List<Routine>> getRoutinesBy(
          {int limit = 50, int offset = 0, required SortableView<Routine> routineSorter}) async =>
      _repository.getRepoListBy(sorter: routineSorter, limit: limit, offset: offset);

  Future<Routine?> getRoutineById({required int id}) async => _repository.getByID(id: id);

  Future<List<Routine>> mostRecent({int limit = 5}) async => _repository.mostRecent(limit: limit);

  Future<void> updateRoutine({required Routine routine}) async => _repository.update(routine);

  Future<void> updateBatch({required List<Routine> routines}) async =>
      _repository.updateBatch(routines);

  Future<void> deleteRoutine({required Routine routine}) async => _repository.delete(routine);

  Future<void> clearDeletesLocalRepo() async => _repository.deleteLocal();

  Future<void> syncRepo() async => _repository.syncRepo();

  Future<void> reorderRoutines(
      {required List<Routine> routines, required int oldIndex, required int newIndex}) async {
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
    _repository.update(routine);
  }

  Future<void> resetRoutines({required List<Routine?> routines}) async {
    List<Routine> toUpdate = List.empty(growable: true);
    for (Routine? routine in routines) {
      if (null != routine) {
        routine.routineTasks.map((rt) => rt.completed = false);
        toUpdate.add(routine);
      }
    }
    _repository.updateBatch(toUpdate);
  }
}
