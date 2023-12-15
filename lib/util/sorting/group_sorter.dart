import '../../model/task/group.dart';
import '../enums.dart';
import '../interfaces/sortable.dart';

class GroupSorter implements SortableView<Group> {
  @override
  bool descending;

  @override
  SortMethod sortMethod;

  GroupSorter({this.descending = false, this.sortMethod = SortMethod.none});

  @override
  final List<SortMethod> sortMethods = [
    SortMethod.none,
    SortMethod.name,
  ];
}
