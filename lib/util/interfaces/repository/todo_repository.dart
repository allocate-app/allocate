import '../../../model/task/todo.dart';
import 'repository.dart';

abstract interface class ToDoRepository implements Repository<ToDo> {
  Future<List<ToDo>> getRepoByGroupID({required int groupID});
  Future<List<ToDo>> getMyDay();
  Future<List<ToDo>> getCompleted();
  Future<List<ToDo>> getRepeatables({DateTime? now});
  Future<void> deleteFutures({required ToDo toDo});

  //TODO: some sort of method to limit the query results?
}
