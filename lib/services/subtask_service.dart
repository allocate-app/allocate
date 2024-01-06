import '../model/task/subtask.dart';
import '../repositories/subtask_repo.dart';
import '../util/constants.dart';
import '../util/enums.dart';
import '../util/interfaces/repository/model/subtask_repository.dart';
import '../util/interfaces/sortable.dart';

class SubtaskService {
  SubtaskRepository _repository = SubtaskRepo();
  SubtaskSorter sorter = SubtaskSorter();

  set repository(SubtaskRepository repo) => _repository = repo;

  Future<Subtask> createSubtask({required Subtask subtask}) async =>
      await _repository.create(subtask);

  Future<Subtask> updateSubtask({required Subtask subtask}) async =>
      await _repository.update(subtask);

  Future<void> updateBatch({required List<Subtask> subtasks}) async =>
      await _repository.updateBatch(subtasks);

  Future<void> deleteSubtask({required Subtask subtask}) async =>
      await _repository.delete(subtask);

  Future<int> getTaskSubtasksCount(
          {required int taskID, int limit = Constants.maxNumTasks}) async =>
      await _repository.getTaskSubtasksCount(taskID: taskID, limit: limit);

  Future<int> getTaskSubtaskWeight(
          {required int taskID, int limit = Constants.maxNumTasks}) async =>
      await _repository.getTotalSubtaskWeight(taskID: taskID, limit: limit);

  Future<void> clearDeletesLocalRepo() async => await _repository.deleteLocal();

  Future<List<Subtask>> reorderSubtasks(
      {required List<Subtask> subtasks,
      required int oldIndex,
      required int newIndex}) async {
    if (oldIndex < newIndex) {
      newIndex--;
    }
    Subtask subtask = subtasks.removeAt(oldIndex);
    subtasks.insert(newIndex, subtask);
    for (int i = 0; i < subtasks.length; i++) {
      subtasks[i].customViewIndex = i;
    }
    await _repository.updateBatch(subtasks);
    return subtasks;
  }

  Future<List<Subtask>> resetSubtasks({required int id}) async {
    List<Subtask> subtasks = await _repository.getRepoByTaskID(id: id);
    for (Subtask st in subtasks) {
      st.completed = false;
    }
    await _repository.updateBatch(subtasks);
    return subtasks;
  }

  Future<List<Subtask>> getTaskSubtasks(
          {required int id, limit = Constants.maxNumTasks}) async =>
      await _repository.getRepoByTaskID(id: id, limit: limit);

  Future<List<Subtask>> getSubtasksBy() async =>
      await _repository.getRepoListBy(
        sorter: sorter,
      );
}

// This is just a partial class for the interface.
// For now, is going unused.
class SubtaskSorter implements SortableView<Subtask> {
  @override
  bool descending = false;

  @override
  SortMethod sortMethod = SortMethod.none;

  @override
  List<SortMethod> get sortMethods =>
      [SortMethod.none, SortMethod.name, SortMethod.weight];
}
