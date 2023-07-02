import '../../model/task/routine.dart';
import '../enums.dart';
import '../interfaces/sortable.dart';

abstract interface class RoutineSortable implements SortableView<Routine>
{
  @override
  late bool descending;

  @override
  late SortMethod sortMethod;

  @override
  late List<SortMethod> sortMethods;

  late RoutineTime timeOfDay;
}

class RoutineSorter implements RoutineSortable
{
  @override
  bool descending = false;

  @override
  SortMethod sortMethod = SortMethod.none;

  @override
  List<SortMethod> sortMethods = [
    SortMethod.none,
    SortMethod.name,
    SortMethod.weight,
    SortMethod.duration
  ];

  @override
  RoutineTime timeOfDay = RoutineTime.morning;

}