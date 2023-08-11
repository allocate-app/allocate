import '../../../../model/task/todo.dart';
import '../function/overdue.dart';
import '../function/repeatable.dart';
import '../function/repository.dart';
import '../function/search.dart';

abstract interface class ToDoRepository
    implements Repository<ToDo>, Search<ToDo>, Overdue<ToDo>, Repeatable<ToDo> {
  Future<List<ToDo>> getRepoByGroupID({required int groupID, int limit, int offset});
  Future<List<ToDo>> getMyDay({int limit, int offset});
  Future<int> getMyDayWeight({int limit, int offset});
  Future<List<ToDo>> getCompleted({int limit, int offset});
}
