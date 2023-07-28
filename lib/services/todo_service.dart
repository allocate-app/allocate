import 'dart:developer';

import 'package:jiffy/jiffy.dart';

import '../model/task/subtask.dart';
import '../model/task/todo.dart';
import '../repositories/todo_repo.dart';
import '../util/constants.dart';
import '../util/enums.dart';
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

  DateTime? getRepeatDate({required ToDo toDo}) => switch (toDo.frequency) {
        (Frequency.daily) => Jiffy.parseFromDateTime(toDo.startDate)
            .add(days: toDo.repeatSkip)
            .dateTime,
        (Frequency.weekly) => Jiffy.parseFromDateTime(toDo.startDate)
            .add(weeks: toDo.repeatSkip)
            .dateTime,
        (Frequency.monthly) => Jiffy.parseFromDateTime(toDo.startDate)
            .add(months: toDo.repeatSkip)
            .dateTime,
        (Frequency.yearly) => Jiffy.parseFromDateTime(toDo.startDate)
            .add(years: toDo.repeatSkip)
            .dateTime,
        (Frequency.custom) => getCustom(toDo: toDo),
        //Once should never repeat -> fixing asynchronously in case validation fails.
        (Frequency.once) => null,
      };

  Future<void> nextRepeatable({required ToDo toDo}) async {
    DateTime? nextRepeatDate = getRepeatDate(toDo: toDo);

    if (null == nextRepeatDate) {
      return;
    }

    int offset = Jiffy.parseFromDateTime(toDo.dueDate)
        .diff(Jiffy.parseFromDateTime(toDo.startDate)) as int;

    ToDo newToDo = toDo.copyWith(
      startDate: nextRepeatDate,
      dueDate: Jiffy.parseFromDateTime(toDo.dueDate)
          .add(microseconds: offset)
          .dateTime,
    );

    return updateToDo(toDo: newToDo);
  }

  Future<void> populateCalendar({required DateTime limit}) async {
    DateTime startTime = DateTime.now();
    while (startTime.isBefore(limit)) {
      List<ToDo> repeatables = await _repository.getRepeatables(now: startTime);

      if (repeatables.isEmpty) {
        break;
      }
      checkRepeating(now: startTime, repeatables: repeatables);

      startTime.add(const Duration(days: 1));
    }
  }

  // This is somewhat hacky, but populateCalendar needs an early escape.
  Future<void> checkRepeating(
      {required DateTime now, List<ToDo>? repeatables}) async {
    List<ToDo> toUpdate = List.empty(growable: true);

    repeatables = repeatables ?? await _repository.getRepeatables(now: now);

    for (ToDo toDo in repeatables) {
      DateTime? nextRepeatDate = getRepeatDate(toDo: toDo);

      if (null == nextRepeatDate) {
        toDo.repeatable = false;
        continue;
      }

      int offset = Jiffy.parseFromDateTime(toDo.dueDate)
          .diff(Jiffy.parseFromDateTime(toDo.startDate)) as int;

      ToDo newToDo = toDo.copyWith(
          startDate: nextRepeatDate,
          dueDate: Jiffy.parseFromDateTime(toDo.dueDate)
              .add(microseconds: offset)
              .dateTime);

      toDo.repeatable = false;
      toUpdate.add(newToDo);
      toUpdate.add(toDo);
    }
    updateBatch(toDos: toUpdate);
  }

  DateTime? getCustom({required ToDo toDo}) {
    int numDays = 1;

    // Weekday is 1-indexed.
    int index = toDo.startDate.weekday % 7;
    while (true) {
      if (toDo.repeatDays[index] = true) {
        break;
      }
      numDays += 1;
      index = (index + 1) % 7;
      // This will only happen if there are no repeat days in the list.
      // This is an error and should be caught during validation.
      // If it does somehow happen, assume it is once repeatable and thus repeated.
      if (numDays > 7) {
        log("Repeat Error: no repeating dates.");
        return null;
      }
    }

    // ie. if it is within the same week.
    if (index + 1 > toDo.startDate.weekday) {
      return Jiffy.parseFromDateTime(toDo.startDate)
          .add(days: numDays)
          .dateTime;
    }

    Jiffy nextRepeatJiffy = Jiffy.parseFromDateTime(toDo.startDate)
        .add(days: numDays)
        .subtract(weeks: 1);

    // These should be handled within the validator.
    switch (toDo.customFreq) {
      case CustomFrequency.weekly:
        return nextRepeatJiffy.add(weeks: toDo.repeatSkip).dateTime;
      case CustomFrequency.monthly:
        return nextRepeatJiffy.add(months: toDo.repeatSkip).dateTime;
      case CustomFrequency.yearly:
        return nextRepeatJiffy.add(years: toDo.repeatSkip).dateTime;
    }
  }

  int calculateRealDuration({int? weight, int? duration}) => (remap(
          x: weight ?? 0,
          inMin: 0,
          inMax: Constants.maxWeight,
          outMin: Constants.lowerBound,
          outMax: Constants.upperBound) *
      (duration ?? 0)).toInt();

  void setRealDuration({required ToDo toDo}) {
    toDo.realDuration = (remap(
            x: toDo.weight,
            inMin: 0,
            inMax: Constants.maxWeight,
            outMin: Constants.lowerBound,
            outMax: Constants.upperBound) *
        toDo.expectedDuration).toInt();
  }

  Future<void> createToDo({required ToDo toDo}) async =>
      _repository.create(toDo);

  Future<List<ToDo>> getToDos() async => _repository.getRepoList();
  Future<List<ToDo>> getToDosBy(
          {required SortableView<ToDo> todoSorter}) async =>
      _repository.getRepoListBy(sorter: todoSorter);

  Future<ToDo?> getToDoByID({required int id}) async =>
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

  Future<void> clearDeletesLocalRepo() async => _repository.deleteLocal();

  Future<void> deleteToDo({required ToDo toDo}) async =>
      _repository.delete(toDo);

  Future<void> deleteFutures({required ToDo toDo}) async =>
      _repository.deleteFutures(toDo: toDo);

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
