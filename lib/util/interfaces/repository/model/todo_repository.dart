import '../../../../model/task/todo.dart';
import '../../sortable.dart';
import '../function/overdue.dart';
import '../function/repeatable.dart';
import '../function/repository.dart';
import '../function/search.dart';
import '../function/upcoming.dart';

abstract interface class ToDoRepository
    implements
        Repository<ToDo>,
        Search<ToDo>,
        Overdue<ToDo>,
        Upcoming<ToDo>,
        Repeatable<ToDo> {
  Future<List<ToDo>> getRepoByGroupID(
      {required int groupID, int limit, int offset});

  Future<List<ToDo>> getMyDay(
      {int limit, int offset, required SortableView<ToDo> sorter});

  Future<int> getMyDayWeight({int limit});

  Future<List<ToDo>> getCompleted(
      {int limit, int offset, required SortableView<ToDo> sorter});
}
