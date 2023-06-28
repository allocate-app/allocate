import '../model/task/routine.dart';
import '../repository/routine_repository.dart';
import '../util/numbers.dart';

class RoutineService{

  /// TODO: Unimplemented CRUD,
  /// Need to update routines, grab sorted views, etc.
  /// Also likely need to add routine subtasks?  That may come via the provider.

  final RoutineRepository _repository;
  RoutineService(this._repository);

  Future<void> createRoutine(Routine r) async => _repository.create(r);

  // This may need to go into another class.
  // ie. Viewmodel.
  Duration realDuration(Routine rt)
  {
    num factor = smoothstep(x: rt.weight, v0: 1, v1: 10);
    return Duration(seconds: (rt.expectedDuration * factor) as int);
  }
}