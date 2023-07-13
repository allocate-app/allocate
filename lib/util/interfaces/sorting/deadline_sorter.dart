import 'package:allocate/util/enums.dart';

import 'sortable.dart';
import '../../../model/task/deadline.dart';

class DeadlineSorter implements SortableView<Deadline> {
  @override
  bool descending = false;

  @override
  SortMethod sortMethod = SortMethod.none;

  static final List<SortMethod> sortMethods = [
    SortMethod.none,
    SortMethod.name,
    SortMethod.dueDate,
    SortMethod.priority
  ];
}