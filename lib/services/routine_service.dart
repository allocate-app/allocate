import 'package:allocate/util/exceptions.dart';
import '../model/task/routine.dart';
import '../model/task/subtask.dart';
import '../repositories/routine_repo.dart';
import '../util/enums.dart';
import '../util/interfaces/routine_repository.dart';
import '../util/interfaces/sortable.dart';
import '../util/numbers.dart';

class RoutineService{

  RoutineService();
  // May need to construct this with the repository...?
  /// TODO: named parameters

  // This is just the default repo. Switch as needed for testing.
  RoutineRepository _repository = RoutineRepo();

  set repository(RoutineRepository repo) => _repository = repo;

  int recalculateWeight({List<SubTask>? routineTasks}) {
    if(null == routineTasks || routineTasks.isEmpty)
      {
        return 0;
      }
    return routineTasks.fold(0, (p, c) => p + c.weight);
  }

  int getRealDuration({required int seconds})
  => (smoothstep(x: seconds, v0: Routine.lowerBound, v1: Routine.upperBound) * seconds) as int;


  Future<void> createRoutine({required Routine routine}) async => _repository.create(routine);

  Future<List<Routine>> getRoutines({RoutineTime timeOfDay = RoutineTime.morning}) async => _repository.getRepoList();
  Future<List<Routine>> getRoutinesBy({RoutineTime timeOfDay = RoutineTime.morning, required SortableView<Routine> routineSorter}) async => _repository.getRepoListBy(sorter: routineSorter);

  Future<void> updateRoutine({required Routine routine}) async => _repository.update(routine);
  Future<void> updateBatch({required List<Routine> routines}) async => _repository.updateBatch(routines);

  Future<void> deleteRoutine({Routine routine}) async => _repository.delete(routine);

  Future<void> retry({List<Routine> routines}) async => _repository.retry(routines);
  // TODO: Figure out how to call this on a timer.
  Future<void> syncRepo() async => _repository.syncRepo();


  Future<void> addRoutineTask({required SubTask subTask, required Routine routine}) async
  {
    if(routine.routineTasks.length >= Routine.maxTasksPerRoutine)
      {
        throw ListLimitExceededException("Routine limit exceeded");
      }

    routine.routineTasks.add(subTask);
    routine.weight += routine.weight;
    updateRoutine(routine: routine);
  }

  Future<void> updateRoutineTask({required int oldWeight, required int newWeight, required Routine routine}) async
  {
    routine.weight += (-oldWeight) + newWeight;
    if(routine.weight < 0)
      {
        routine.weight = 0;
      }
    updateRoutine(routine: routine);
  }

  Future<void> deleteRoutineTask({required SubTask subTask, required Routine routine}) async
  {
    bool removed = routine.routineTasks.remove(subTask);
    if(removed)
      {
        routine.weight -= routine.weight;
      }
    updateRoutine(routine: routine);
  }


  Future<void> reorderRoutines({required List<Routine> routines, required int oldIndex, required int newIndex}) async{
    if(oldIndex < newIndex)
      {
        newIndex--;
      }
    Routine routine = routines.removeAt(oldIndex);
    routines.insert(newIndex, routine);
    for(int i = 0; i < routines.length; i++)
      {
        routines[i].customViewIndex = i;
      }
    _repository.updateBatch(routines);
  }

  Future<void>reorderRoutineTask({required Routine routine, required int oldIndex, required int newIndex}) async {
    if(oldIndex < newIndex)
      {
        newIndex--;
      }
    SubTask st = routine.routineTasks.removeAt(oldIndex);
    routine.routineTasks.insert(newIndex, st);
    updateRoutine(routine: routine);
  }

}