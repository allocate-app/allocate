import '../../../model/task/group.dart';
import '../../enums.dart';
import 'sortable.dart';

class GroupSorter implements SortableView<Group> {
  @override
  bool descending = false;

  @override
  SortMethod sortMethod = SortMethod.none;

  @override
  static final List<SortMethod> sortMethods = [
    SortMethod.none,
    SortMethod.name,
  ];
}
