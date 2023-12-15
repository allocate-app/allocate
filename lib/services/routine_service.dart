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

  int calculateWeight({List<Subtask>? routineTasks}) =>
      (routineTasks ?? List.empty(growable: false))
          .fold(0, (p, c) => p + c.weight);

  void recalculateWeight({required Routine routine}) {
    routine.weight = routine.subtasks.fold(0, (p, c) => p + c.weight);
  }

  int calculateRealDuration({int? weight, int? duration}) => (remap(
              x: weight ?? 0,
              inMin: 0,
              inMax: Constants.maxWeight,
              outMin: Constants.lowerBound,
              outMax: Constants.upperBound) *
          (duration ?? 0))
      .toInt();

  void setRealDuration({required Routine routine}) =>
      routine.realDuration = (remap(
                  x: routine.weight,
                  inMin: 0,
                  inMax: Constants.maxWeight,
                  outMin: Constants.lowerBound,
                  outMax: Constants.upperBound) *
              routine.expectedDuration)
          .toInt();

  Future<Routine> createRoutine({required Routine routine}) async =>
      await _repository.create(routine);

  Future<List<Routine>> searchRoutines({required String searchString}) async =>
      await _repository.search(searchString: searchString);

  Future<List<Routine>> getRoutines({int limit = 50, int offset = 0}) async =>
      await _repository.getRepoList(limit: limit, offset: offset);

  Future<List<Routine>> getRoutinesBy(
          {int limit = 50,
          int offset = 0,
          required SortableView<Routine> routineSorter}) async =>
      await _repository.getRepoListBy(
          sorter: routineSorter, limit: limit, offset: offset);

  Future<Routine?> getRoutineByID({int? id}) async =>
      (null != id) ? await _repository.getByID(id: id) : null;

  Future<List<Routine>> mostRecent({int limit = 5}) async =>
      await _repository.mostRecent(limit: limit);

  Future<Routine> updateRoutine({required Routine routine}) async =>
      await _repository.update(routine);

  Future<void> updateBatch({required List<Routine> routines}) async =>
      await _repository.updateBatch(routines);

  Future<void> deleteRoutine({required Routine routine}) async =>
      await _repository.delete(routine);

  Future<void> clearDeletesLocalRepo() async => await _repository.deleteLocal();

  Future<void> syncRepo() async => await _repository.syncRepo();

  Future<List<Routine>> reorderRoutines(
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
    await _repository.updateBatch(routines);
    return routines;
  }
}
