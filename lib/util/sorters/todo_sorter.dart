import '../../model/task/todo.dart';
import '../enums.dart';
import '../interfaces/sortable.dart';

class ToDoSorter implements SortableView<ToDo>
{
  @override
  bool descending = false;

  @override
  SortMethod sortMethod = SortMethod.none;

  @override
  List<SortMethod> sortMethods = List.from(SortMethod.values);

}