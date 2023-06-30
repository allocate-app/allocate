import 'package:allocate/util/exceptions.dart';

import '../model/task/routine.dart';
import '../model/task/subtask.dart';
import '../util/enums.dart';
import '../util/interfaces/repository.dart';
import '../util/numbers.dart';

class RoutineService{

  // May need to construct this with the repository...?
  /// TODO: Unimplemented CRUD,
  /// TODO: named paraemeters.
  /// Need to update routines, grab sorted views, etc.
  /// Also likely need to add routine subtasks?  That may come via the provider.
  static final RoutineService _instance = RoutineService._internal();
  static RoutineService get instance => _instance;

  late Repository<Routine> _repository;

  set repository(Repository<Routine> repo) => _repository = repo;

  Future<void> createRoutine(Routine r) async => _repository.create(r);


  Future<List<Routine>> getRoutines() async => _repository.getRepoList();
  Future<List<Routine>> getRoutinesBy({SortMethod sortMethod = SortMethod.none}) async => _repository.getRepoListBy(sortMethod: sortMethod);

  Future<void> updateRoutine(Routine rt) async => _repository.update(rt);
  Future<void> updateBatch(List<Routine> routines) async => _repository.updateBatch(routines);
  Future<void> retry(List<Routine> routines) async => _repository.retry(routines);
  Future<void> deleteRoutine (Routine rt) async => _repository.delete(rt);

  Future<void> addRoutineTask(SubTask st, Routine rt) async
  {
    if(rt.routineTasks.length >= Routine.maxTasksPerRoutine)
      {
        throw ListLimitExceededException("Routine limit exceeded");
      }

    rt.routineTasks.add(st);
    rt.weight += rt.weight;
    updateRoutine(rt);
  }
  Future<void> deleteRoutineTask(SubTask st, Routine rt) async
  {
    bool removed = rt.routineTasks.remove(st);
    if(removed)
      {
        rt.weight -= rt.weight;
      }
    updateRoutine(rt);
  }

  Future<void> recalculateWeight(Routine rt) async
  {
    rt.weight = rt.routineTasks.fold(0, (p, c) => p + c.weight);
    updateRoutine(rt);
  }

  Future<void> reorderRoutines(List<Routine> routines, int oldIndex, int newIndex) async{
    if(oldIndex < newIndex)
      {
        newIndex--;
      }
    Routine rt = routines.removeAt(oldIndex);
    routines.insert(newIndex, rt);
    for(int i = 0; i < routines.length; i++)
      {
        routines[i].customViewIndex = i;
      }
    _repository.updateBatch(routines);
  }

  Future<void>reorderRoutineTask(Routine rt, int oldIndex, int newIndex) async {
    if(oldIndex < newIndex)
      {
        newIndex--;
      }
    SubTask st = rt.routineTasks.removeAt(oldIndex);
    rt.routineTasks.insert(newIndex, st);
    updateRoutine(rt);
  }

  RoutineService._internal();
}