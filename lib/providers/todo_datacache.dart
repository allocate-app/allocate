import "../model/task/todo.dart";
import "../util/interfaces/datacache.dart";

class ToDoDataCache implements DataCache<ToDo>
{
  static final ToDoDataCache _instance = ToDoDataCache._internal();
  static ToDoDataCache get instance => _instance;

  @override
  late ToDo current;
  @override
  List<ToDo> currents = List.empty(growable: true);
  @override
  // TODO: implement cache
  final List<ToDo> cache = List.empty(growable: true);

  ToDoDataCache._internal();

}