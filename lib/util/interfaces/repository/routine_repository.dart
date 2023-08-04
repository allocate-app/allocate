import '../../../model/task/routine.dart';
import '../../enums.dart';
import '../sortable.dart';
import 'repository.dart';

abstract interface class RoutineRepository implements Repository<Routine> {
  @override
  Future<List<Routine>> getRepoList(
      {RoutineTime timeOfDay = RoutineTime.morning});
  @override
  Future<List<Routine>> getRepoListBy(
      {RoutineTime timeOfDay = RoutineTime.morning,
      required SortableView<Routine> sorter});
}
