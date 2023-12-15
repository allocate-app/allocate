import '../../model/task/deadline.dart';
import '../enums.dart';
import '../interfaces/sortable.dart';

class DeadlineSorter implements SortableView<Deadline> {
  @override
  bool descending = false;

  @override
  SortMethod sortMethod = SortMethod.none;

  DeadlineSorter({this.descending = false, this.sortMethod = SortMethod.none});

  @override
  final List<SortMethod> sortMethods = [
    SortMethod.none,
    SortMethod.name,
    SortMethod.due_date,
    SortMethod.priority
  ];
}
