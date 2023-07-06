import 'repository.dart';
import '../../model/task/todo.dart';

abstract interface class ToDoRepository implements Repository<ToDo>
{
  Future<List<ToDo>> getRepoByGroupID({required int groupID});
  Future<List<ToDo>> getMyDay();
  Future<List<ToDo>> getCompleted();

  //TODO: some sort of method to limit the query results.
}