import '../model/task/subtask.dart';
import '../model/task/todo.dart';
import '../repositories/todo_repo.dart';
import '../util/constants.dart';
import '../util/exceptions.dart';
import '../util/interfaces/repository/todo_repository.dart';
import '../util/interfaces/sortable.dart';
import '../util/numbers.dart';

class ToDoService {
  ToDoService();

  // This is just the default repo. Switch as needed for testing.
  ToDoRepository _repository = ToDoRepo();

  set repository(ToDoRepository repo) => _repository = repo;

  int calculateWeight({List<SubTask>? subTasks}) =>
      (subTasks ?? List.empty(growable: false)).fold(0, (p, c) => p + c.weight);

  void recalculateWeight({required ToDo toDo}) {
    toDo.weight = toDo.subTasks.fold(0, (p, c) => p + c.weight);
  }

  int calculateRealDuration({int? weight, int? duration}) => (remap(
          x: weight ?? 0,
          inMin: 0,
          inMax: Constants.maxWeight,
          outMin: Constants.lowerBound,
          outMax: Constants.upperBound) *
      (duration ?? 0)) as int;

  void setRealDuration({required ToDo toDo}) {
    toDo.realDuration = (remap(
            x: toDo.weight,
            inMin: 0,
            inMax: Constants.maxWeight,
            outMin: Constants.lowerBound,
            outMax: Constants.upperBound) *
        toDo.expectedDuration) as int;
  }

  Future<void> createToDo({required ToDo toDo}) async =>
      _repository.create(toDo);

  Future<List<ToDo>> getToDos() async => _repository.getRepoList();
  Future<List<ToDo>> getToDosBy(
          {required SortableView<ToDo> todoSorter}) async =>
      _repository.getRepoListBy(sorter: todoSorter);

  Future<ToDo> getToDoByID({required int id}) async =>
      _repository.getByID(id: id);

  Future<List<ToDo>> getMyDay() async => _repository.getMyDay();
  Future<List<ToDo>> getByGroup({required int groupID}) async =>
      _repository.getRepoByGroupID(groupID: groupID);
  Future<List<ToDo>> getCompleted() async => _repository.getCompleted();

  Future<void> updateToDo({required ToDo toDo}) async {
    if (toDo.subTasks.length > Constants.numTasks[toDo.taskType]!) {
      throw ListLimitExceededException(
          "Validation failed, subtask limit mismatch");
    }
    return _repository.update(toDo);
  }

  Future<void> updateBatch({required List<ToDo> toDos}) async =>
      _repository.updateBatch(toDos);

  Future<void> deleteToDo({required ToDo toDo}) async =>
      _repository.delete(toDo);

  Future<void> retry({required List<ToDo> toDos}) async =>
      _repository.retry(toDos);

  Future<void> syncRepo() async => _repository.syncRepo();

  Future<void> addSubTask(
      {required SubTask subTask, required ToDo toDo}) async {
    if (toDo.subTasks.length >= Constants.numTasks[toDo.taskType]!) {
      throw ListLimitExceededException("Max subtasks limit exceeded");
    }
    toDo.subTasks.add(subTask);
    toDo.weight += toDo.weight;
    updateToDo(toDo: toDo);
  }

  Future<void> updateSubTask(
      {required int oldWeight,
      required int index,
      required SubTask subTask,
      required ToDo toDo}) async {
    toDo.subTasks[index] = subTask;
    toDo.weight += (-oldWeight) + subTask.weight;

    if (toDo.weight < 0) {
      toDo.weight = 0;
    }
    updateToDo(toDo: toDo);
  }

  Future<void> deleteSubTask(
      {required SubTask subTask, required ToDo toDo}) async {
    bool removed = toDo.subTasks.remove(subTask);
    if (removed) {
      toDo.weight -= subTask.weight;
    }
    updateToDo(toDo: toDo);
  }

  Future<void> reorderSubTask(
      {required ToDo toDo,
      required int oldIndex,
      required int newIndex}) async {
    if (oldIndex < newIndex) {
      newIndex--;
    }
    SubTask st = toDo.subTasks.removeAt(oldIndex);
    toDo.subTasks.insert(newIndex, st);
    updateToDo(toDo: toDo);
  }

  Future<void> toggleMyDay({required ToDo toDo}) async {
    toDo.myDay = !toDo.myDay;
    updateToDo(toDo: toDo);
  }

  // This is for my day.
  Future<void> reorderTodos(
      {required List<ToDo> toDos,
      required int oldIndex,
      required int newIndex}) async {
    if (oldIndex < newIndex) {
      newIndex--;
    }
    ToDo toDo = toDos.removeAt(oldIndex);
    toDos.insert(newIndex, toDo);
    for (int i = 0; i < toDos.length; i++) {
      toDos[i].customViewIndex = i;
    }
    _repository.updateBatch(toDos);
  }

  Future<void> reorderGroupTasks(
      {required List<ToDo> toDos,
      required int oldIndex,
      required int newIndex}) async {
    if (oldIndex < newIndex) {
      newIndex--;
    }
    ToDo todo = toDos.removeAt(oldIndex);
    toDos.insert(newIndex, todo);
    for (int i = 0; i < toDos.length; i++) {
      toDos[i].groupIndex = i;
    }
    _repository.updateBatch(toDos);
  }
}
