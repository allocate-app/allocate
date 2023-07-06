import '../model/task/todo.dart';
import '../util/interfaces/sortable.dart';
import '../util/interfaces/todo_repository.dart';
import '../util/numbers.dart';

class ToDoService
{

  static final ToDoService _instance = ToDoService._internal();
  static ToDoService get instance => _instance;

  late ToDoRepository _repository;

  set repository(ToDoRepository repo) => _repository = repo;

  Future<void> createToDo(ToDo t) async => _repository.create(t);
  Future<void> updateToDo(ToDo t) async => _repository.update(t);
  Future<void> updateBatch(List<ToDo> todos) async => _repository.updateBatch(todos);

  Future<List<ToDo>> getToDos() async => _repository.getRepoList();
  Future<List<ToDo>> getToDosBy({required SortableView<ToDo> todoSorter}) async => _repository.getRepoListBy(sorter:todoSorter);

  // This may actually be able to stay.
  Duration realDuration(ToDo t) {
    num factor = smoothstep(x: t.weight, v0: 1, v1: 10);
    return Duration(seconds: (t.expectedDuration * factor) as int);
  }

  ToDoService._internal();
}