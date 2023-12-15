import '../../model/task/routine.dart';
import '../enums.dart';
import '../interfaces/sortable.dart';

class RoutineSorter implements SortableView<Routine> {
  @override
  bool descending = false;

  @override
  SortMethod sortMethod = SortMethod.none;

  RoutineSorter({this.descending = false, this.sortMethod = SortMethod.none});

  @override
  final List<SortMethod> sortMethods = [
    SortMethod.none,
    SortMethod.name,
    SortMethod.weight,
    SortMethod.duration
  ];
}
