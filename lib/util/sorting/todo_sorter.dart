import '../../model/task/todo.dart';
import '../enums.dart';
import '../interfaces/sortable.dart';

class ToDoSorter implements SortableView<ToDo> {
  @override
  bool descending = false;

  @override
  SortMethod sortMethod = SortMethod.none;

  ToDoSorter({this.descending = false, this.sortMethod = SortMethod.none});

  @override
  final List<SortMethod> sortMethods = List.from(SortMethod.values);
}
