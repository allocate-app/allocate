import '../../../model/task/routine.dart';
import '../../enums.dart';
import 'sortable.dart';

class RoutineSorter implements SortableView<Routine> {
  @override
  bool descending = false;

  @override
  SortMethod sortMethod = SortMethod.none;

  static final List<SortMethod> sortMethods = [
    SortMethod.none,
    SortMethod.name,
    SortMethod.weight,
    SortMethod.duration
  ];
}
