import '../../../../model/task/subtask.dart';
import '../../../constants.dart';
import '../function/repository.dart';

abstract interface class SubtaskRepository implements Repository<Subtask> {
  Future<List<Subtask>> getRepoByTaskID(
      {required int id, int limit = Constants.maxNumTasks, int offset = 0});

  Future<int> getTaskSubtasksCount(
      {required int taskID, int limit = Constants.maxNumTasks});

  Future<int> getTaskSubtaskWeight(
      {required int taskID, int limit = Constants.maxNumTasks});
}
