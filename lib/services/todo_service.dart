import '../model/task/subtask.dart';
import '../model/task/todo.dart';
import '../repositories/subtask_repo.dart';
import '../repositories/todo_repo.dart';
import '../util/constants.dart';
import '../util/enums.dart';
import '../util/interfaces/repository/model/subtask_repository.dart';
import '../util/interfaces/repository/model/todo_repository.dart';
import '../util/interfaces/sortable.dart';
import '../util/numbers.dart';

class ToDoService {
  ToDoRepository _repository = ToDoRepo();
  SubtaskRepository _subtaskRepository = SubtaskRepo();

  set repository(ToDoRepository repo) => _repository = repo;

  // This seems like the least awkward way to handle subtasks.
  set subtaskRepository(SubtaskRepository subtaskRepo) =>
      _subtaskRepository = subtaskRepo;

  int calculateWeight({List<Subtask>? subtasks}) =>
      (subtasks ?? List.empty(growable: false)).fold(0, (p, c) => p + c.weight);

  void recalculateWeight({required ToDo toDo}) {
    toDo.weight = toDo.subtasks.fold(0, (p, c) => p + c.weight);
  }

  int calculateRealDuration({int? weight, int? duration}) => (remap(
              x: weight ?? 0,
              inMin: 0,
              inMax: Constants.medianWeight,
              outMin: Constants.lowerBound,
              outMax: Constants.upperBound) *
          (duration ?? 0))
      .toInt();

  int getDateTimeDayOffset({required DateTime start, required DateTime end}) {
    start = DateTime.utc(start.year, start.month, start.day, start.hour,
        start.minute, start.second, start.millisecond, start.microsecond);
    end = DateTime.utc(end.year, end.month, end.day, end.hour, end.minute,
        end.second, end.millisecond, end.microsecond);
    return end.difference(start).inDays;
  }

  void setRealDuration({required ToDo toDo}) {
    toDo.realDuration = (remap(
                x: toDo.weight,
                inMin: 0,
                inMax: Constants.medianWeight,
                outMin: Constants.lowerBound,
                outMax: Constants.upperBound) *
            toDo.expectedDuration)
        .toInt();
  }

  DateTime? getRepeatDate({required ToDo toDo}) => switch (toDo.frequency) {
        (Frequency.daily) => toDo.startDate!.copyWith(
            day: toDo.startDate!.day + toDo.repeatSkip,
            hour: toDo.startDate!.hour,
            minute: toDo.startDate!.minute),
        (Frequency.weekly) => toDo.startDate!.copyWith(
            day: toDo.startDate!.day + (toDo.repeatSkip * 7),
            hour: toDo.startDate!.hour,
            minute: toDo.startDate!.minute),
        (Frequency.monthly) => toDo.startDate!.copyWith(
            month: toDo.startDate!.month + toDo.repeatSkip,
            hour: toDo.startDate!.hour,
            minute: toDo.startDate!.minute),
        (Frequency.yearly) => toDo.startDate!.copyWith(
            year: toDo.startDate!.year + toDo.repeatSkip,
            hour: toDo.startDate!.hour,
            minute: toDo.startDate!.minute),
        (Frequency.custom) => getCustom(toDo: toDo),
        //Once should never repeat -> fixing asynchronously in case validation fails.
        (Frequency.once) => null,
      };

  Future<int> getMyDayWeight() async => await _repository.getMyDayWeight();

  Future<int> getGroupToDoCount({required int groupID}) async =>
      await _repository.getGroupToDoCount(groupID: groupID);

  Future<void> nextRepeatable({required ToDo toDo}) async {
    List<Subtask> subtasksToUpdate = List.empty(growable: true);
    DateTime? nextRepeatDate = getRepeatDate(toDo: toDo);

    if (null == nextRepeatDate) {
      return;
    }

    int offset =
        getDateTimeDayOffset(start: toDo.startDate!, end: toDo.dueDate!);

    ToDo newToDo = toDo.copyWith(
      startDate: nextRepeatDate,
      dueDate: nextRepeatDate.copyWith(
          day: nextRepeatDate.day + offset,
          hour: toDo.dueDate!.hour,
          minute: toDo.dueDate!.minute),
      completed: false,
      myDay: false,
      lastUpdated: DateTime.now(),
    );

    // if the toDo has subtasks, grab and duplicate.
    // calculate weight based on task size.
    if (TaskType.small != toDo.taskType) {
      List<Subtask> subtasks =
          await _subtaskRepository.getRepoByTaskID(id: toDo.id);
      int newWeight = 0;
      int i = 0;
      for (Subtask subtask in subtasks) {
        subtasksToUpdate
            .add(subtask.copyWith(completed: false, taskID: newToDo.id));
        if (i < Constants.numTasks[newToDo.taskType]!) {
          newWeight += subtask.weight;
          i++;
        }
      }
      newToDo.weight = newWeight;
    }

    toDo.repeatable = false;

    await _repository.updateBatch([toDo, newToDo]);
    await _subtaskRepository.updateBatch(subtasksToUpdate);
  }

  // Future<void> populateCalendar({required DateTime limit}) async {
  //   DateTime startTime = DateTime.now();
  //   while (startTime.isBefore(limit)) {
  //     List<ToDo> repeatables = await _repository.getRepeatables(now: startTime);
  //
  //     await checkRepeating(now: startTime, repeatables: repeatables)
  //         .whenComplete(() {
  //       startTime = startTime.copyWith(day: startTime.day + 1);
  //     });
  //   }
  // }

  // Future<void> checkRepeating(
  //     {required DateTime now, List<ToDo>? repeatables}) async {
  //   List<ToDo> toDosToUpdate = List.empty(growable: true);
  //   List<Subtask> subtasksToUpdate = List.empty(growable: true);
  //
  //   repeatables = repeatables ?? await _repository.getRepeatables(now: now);
  //
  //   for (ToDo toDo in repeatables) {
  //     DateTime? nextRepeatDate = getRepeatDate(toDo: toDo);
  //
  //     if (null == nextRepeatDate) {
  //       toDo.repeatable = false;
  //       toDosToUpdate.add(toDo);
  //       continue;
  //     }
  //     int offset =
  //         getDateTimeDayOffset(start: toDo.startDate!, end: toDo.dueDate!);
  //
  //     DateTime nextDueDate = nextRepeatDate.copyWith(
  //         hour: toDo.dueDate!.hour,
  //         minute: toDo.dueDate!.minute,
  //         day: nextRepeatDate.day + offset);
  //
  //     ToDo newToDo = toDo.copyWith(
  //         completed: false,
  //         myDay: false,
  //         startDate: nextRepeatDate,
  //         dueDate: nextDueDate,
  //         lastUpdated: DateTime.now());
  //
  //     // if the task has subtasks, grab and duplicate.
  //     if (TaskType.small != toDo.taskType) {
  //       List<Subtask> subtasks =
  //           await _subtaskRepository.getRepoByTaskID(id: toDo.id);
  //       int newWeight = 0;
  //       int i = 0;
  //       for (Subtask subtask in subtasks) {
  //         subtasksToUpdate
  //             .add(subtask.copyWith(completed: false, taskID: newToDo.id));
  //         if (i < Constants.numTasks[newToDo.taskType]!) {
  //           newWeight += subtask.weight;
  //           i++;
  //         }
  //       }
  //
  //       newToDo.weight = newWeight;
  //     }
  //
  //     toDo.repeatable = false;
  //     toDosToUpdate.add(newToDo);
  //     toDosToUpdate.add(toDo);
  //   }
  //   await _repository.updateBatch(toDosToUpdate);
  //   await _subtaskRepository.updateBatch(subtasksToUpdate);
  // }

  DateTime? getCustom({required ToDo toDo}) {
    int start = toDo.startDate!.weekday - 1;
    int end = 0;
    if (start + 1 != 7) {
      end = toDo.repeatDays.indexOf(true, start + 1);
      if (end > 0) {
        return toDo.startDate!.copyWith(
            day: toDo.startDate!.day + (end - start),
            hour: toDo.startDate!.hour,
            minute: toDo.startDate!.minute);
      }
    }
    end = toDo.repeatDays.indexOf(true);
    int offset = end - start;
    DateTime nextDate =
        toDo.startDate!.copyWith(day: toDo.startDate!.day + offset);

    nextDate = nextDate.copyWith(
        day: nextDate.day + (7 * toDo.repeatSkip),
        hour: toDo.startDate!.hour,
        minute: toDo.startDate!.minute,
        second: 0,
        millisecond: 0,
        microsecond: 0);

    // This is to compensate for leap-years and 30/31 day issues
    int edgeOffset = end - nextDate.weekday + 1;
    nextDate = nextDate.copyWith(day: nextDate.day + edgeOffset);

    return nextDate;
  }

  Future<ToDo> createToDo({required ToDo toDo}) async =>
      await _repository.create(toDo);

  Future<List<ToDo>> searchToDos({required String searchString}) async =>
      await _repository.search(searchString: searchString);

  Future<List<ToDo>> getToDos({int limit = 50, int offset = 0}) async =>
      await _repository.getRepoList(limit: limit, offset: offset);

  Future<List<ToDo>> getToDosBy(
          {required SortableView<ToDo> toDoSorter,
          int limit = 50,
          int offset = 0}) async =>
      await _repository.getRepoListBy(
          sorter: toDoSorter, limit: limit, offset: offset);

  Future<List<ToDo>> getRange({DateTime? start, DateTime? end}) async =>
      await _repository.getRange(start: start, end: end);

  Future<List<ToDo>> getOverdues({int limit = 50, int offset = 0}) async =>
      await _repository.getOverdues(limit: limit, offset: offset);

  Future<List<ToDo>> getUpcoming({int limit = 50, int offset = 0}) async =>
      await _repository.getUpcoming(limit: limit, offset: offset);

  Future<ToDo?> getToDoByID({int? id}) async =>
      (null != id) ? await _repository.getByID(id: id) : null;

  Future<List<ToDo>> mostRecent({int limit = 5}) async =>
      await _repository.mostRecent(limit: limit);

  Future<List<ToDo>> getMyDay(
          {required SortableView<ToDo> toDoSorter,
          int limit = 50,
          int offset = 0}) async =>
      await _repository.getMyDay(
          sorter: toDoSorter, limit: limit, offset: offset);

  Future<List<ToDo>> getByGroup(
      {int? groupID, int limit = 50, int offset = 0}) async {
    if (null == groupID) {
      return [];
    }
    return await _repository.getRepoByGroupID(
        groupID: groupID, limit: limit, offset: offset);
  }

  Future<List<ToDo>> getCompleted(
          {required SortableView<ToDo> toDoSorter,
          int limit = 50,
          int offset = 0}) async =>
      await _repository.getCompleted(
          sorter: toDoSorter, limit: limit, offset: offset);

  Future<ToDo> updateToDo({required ToDo toDo}) async =>
      await _repository.update(toDo);

  Future<void> updateBatch({required List<ToDo> toDos}) async =>
      await _repository.updateBatch(toDos);

  Future<void> deleteToDo({required ToDo toDo}) async =>
      await _repository.delete(toDo);

  Future<void> clearDeletesLocalRepo() async => _repository.deleteLocal();

  Future<List<int>> deleteFutures({required ToDo toDo}) async =>
      await _repository.deleteFutures(deleteFrom: toDo);

  Future<void> syncRepo() async => await _repository.syncRepo();

  // This is for my day && listview screens.
  // preserves relative order for both screens.
  Future<List<ToDo>> reorderTodos(
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
    await _repository.updateBatch(toDos);
    return toDos;
  }

  Future<List<ToDo>> reorderGroupToDos(
      {required List<ToDo> toDos,
      required int oldIndex,
      required int newIndex}) async {
    if (oldIndex < newIndex) {
      newIndex--;
    }
    ToDo toDo = toDos.removeAt(oldIndex);
    toDos.insert(newIndex, toDo);
    for (int i = 0; i < toDos.length; i++) {
      toDos[i].groupIndex = i;
    }
    await _repository.updateBatch(toDos);
    return toDos;
  }
}
