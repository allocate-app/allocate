import '../model/task/routine.dart';
import '../repository/routine_repository.dart';
import '../util/interfaces/repository.dart';
import '../util/numbers.dart';

class RoutineService{

  // May need to construct this with the repository...?
  /// TODO: Unimplemented CRUD,
  /// Need to update routines, grab sorted views, etc.
  /// Also likely need to add routine subtasks?  That may come via the provider.
  static final RoutineService _instance = RoutineService._internal();
  static RoutineService get instance => _instance;

  late Repository<Routine> _repository;

  set repository(Repository<Routine> repo) => _repository = repo;

  Future<void> createRoutine(Routine r) async => _repository.create(r);

  Future<List<Routine>> getRoutines() async => _repository.getRepoList();
  // This may need to go into another class.
  Duration realDuration(Routine rt)
  {
    num factor = smoothstep(x: rt.weight, v0: 1, v1: 10);
    return Duration(seconds: (rt.expectedDuration * factor) as int);
  }

  RoutineService._internal();
}