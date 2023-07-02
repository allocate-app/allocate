import '../../model/task/todo.dart';
import '../enums.dart';
import '../interfaces/sortable.dart';

abstract interface class ToDoSortable implements SortableView<ToDo>
{
  @override
  late bool descending;

  @override
  late SortMethod sortMethod;

  @override
  late List<SortMethod> sortMethods;

}

class ToDoSorter implements ToDoSortable
{
  @override
  bool descending = false;

  @override
  SortMethod sortMethod = SortMethod.none;

  // TODO: write the implementation for this.
  @override
  List<SortMethod> sortMethods = List.empty(growable: true);

}