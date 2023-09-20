import 'dart:developer';

import 'package:jiffy/jiffy.dart';

import '../model/task/subtask.dart';
import '../model/task/todo.dart';
import '../repositories/todo_repo.dart';
import '../util/constants.dart';
import '../util/enums.dart';
import '../util/interfaces/repository/model/todo_repository.dart';
import '../util/interfaces/sortable.dart';
import '../util/numbers.dart';

class ToDoService {
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
          (duration ?? 0))
      .toInt();

  void setRealDuration({required ToDo toDo}) {
    toDo.realDuration = (remap(
                x: toDo.weight,
                inMin: 0,
                inMax: Constants.maxWeight,
                outMin: Constants.lowerBound,
                outMax: Constants.upperBound) *
            toDo.expectedDuration)
        .toInt();
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

  Future<int> getMyDayWeight() async => await _repository.getMyDayWeight();

  Future<void> nextRepeatable({required ToDo toDo}) async {
    DateTime? nextRepeatDate = getRepeatDate(toDo: toDo);

    if (null == nextRepeatDate) {
      return;
    }

    int offset = Jiffy.parseFromDateTime(toDo.dueDate)
        .diff(Jiffy.parseFromDateTime(toDo.startDate)) as int;

    ToDo newToDo = toDo.copyWith(
      startDate: nextRepeatDate,
      dueDate: Jiffy.parseFromDateTime(nextRepeatDate)
          .add(microseconds: offset)
          .dateTime,
      completed: false,
      myDay: false,
    );

    return updateToDo(toDo: newToDo);
  }

  Future<void> populateCalendar({required DateTime limit}) async {
    DateTime startTime = DateTime.now();
    while (startTime.isBefore(limit)) {
      List<ToDo> repeatables = await _repository.getRepeatables(now: startTime);

      await checkRepeating(now: startTime, repeatables: repeatables)
          .whenComplete(() {
        startTime = startTime.add(const Duration(days: 1));
      });
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
        toUpdate.add(toDo);
        continue;
      }

      int offset = Jiffy.parseFromDateTime(toDo.dueDate)
          .diff(Jiffy.parseFromDateTime(toDo.startDate)) as int;

      ToDo newToDo = toDo.copyWith(
          completed: false,
          myDay: false,
          startDate: nextRepeatDate,
          dueDate: Jiffy.parseFromDateTime(nextRepeatDate)
              .add(microseconds: offset)
              .dateTime);

      toDo.repeatable = false;
      toUpdate.add(newToDo);
      toUpdate.add(toDo);
    }
    await updateBatch(toDos: toUpdate);
  }

  DateTime? getCustom({required ToDo toDo}) {
    int numDays = 1;

    // Weekday is 1-indexed.
    int index = toDo.startDate.weekday % 7;
    while (true) {
      if (toDo.repeatDays[index] == true) {
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

  Future<void> createToDo({required ToDo toDo}) async =>
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

  Future<void> updateToDo({required ToDo toDo}) async =>
      await _repository.update(toDo);

  Future<void> updateBatch({required List<ToDo> toDos}) async =>
      await _repository.updateBatch(toDos);

  Future<void> deleteToDo({required ToDo toDo}) async =>
      await _repository.delete(toDo);

  Future<void> clearDeletesLocalRepo() async => _repository.deleteLocal();

  Future<void> deleteFutures({required ToDo toDo}) async =>
      await _repository.deleteFutures(deleteFrom: toDo);

  Future<void> syncRepo() async => await _repository.syncRepo();

  // Likely better to not use.
  Future<void> toggleMyDay({required ToDo toDo}) async {
    toDo.myDay = !toDo.myDay;
    _repository.update(toDo);
  }

  // This is for my day.
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
    _repository.updateBatch(toDos);
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
