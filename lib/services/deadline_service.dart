import 'dart:developer';

import 'package:jiffy/jiffy.dart';

import '../model/task/deadline.dart';
import '../repositories/deadline_repo.dart';
import '../util/enums.dart';
import '../util/interfaces/repository/model/deadline_repository.dart';
import '../util/interfaces/sortable.dart';
import 'notification_service.dart';

class DeadlineService {
  DeadlineRepository _repository = DeadlineRepo();

  set repository(DeadlineRepository repo) => _repository = repo;

  DateTime? getRepeatDate({required Deadline deadline}) =>
      switch (deadline.frequency) {
        (Frequency.daily) =>
        Jiffy
            .parseFromDateTime(deadline.startDate)
            .add(days: deadline.repeatSkip)
            .dateTime,
        (Frequency.weekly) =>
        Jiffy
            .parseFromDateTime(deadline.startDate)
            .add(weeks: deadline.repeatSkip)
            .dateTime,
        (Frequency.monthly) =>
        Jiffy
            .parseFromDateTime(deadline.startDate)
            .add(months: deadline.repeatSkip)
            .dateTime,
        (Frequency.yearly) =>
        Jiffy
            .parseFromDateTime(deadline.startDate)
            .add(years: deadline.repeatSkip)
            .dateTime,
        (Frequency.custom) => getCustom(deadline: deadline),
      //Once should never repeat -> fixing asynchronously in case validation fails.
        (Frequency.once) => null,
      };

  Future<void> nextRepeatable({required Deadline deadline}) async {
    DateTime? nextRepeatDate = getRepeatDate(deadline: deadline);

    if (null == nextRepeatDate) {
      return;
    }

    int dueOffset = Jiffy.parseFromDateTime(deadline.dueDate)
        .diff(Jiffy.parseFromDateTime(deadline.startDate)) as int;

    int warnOffset = Jiffy.parseFromDateTime(deadline.warnDate)
        .diff(Jiffy.parseFromDateTime(deadline.startDate)) as int;

    Deadline newDeadline = deadline.copyWith(
        startDate: nextRepeatDate,
        dueDate: Jiffy
            .parseFromDateTime(nextRepeatDate)
            .add(microseconds: dueOffset)
            .dateTime,
        warnDate: Jiffy
            .parseFromDateTime(nextRepeatDate)
            .add(microseconds: warnOffset)
            .dateTime);

    // Scheduling logic.
    newDeadline.notificationID = newDeadline.hashCode;
    if (newDeadline.warnMe &&
        NotificationService.instance
            .validateWarnDate(warnDate: newDeadline.warnDate)) {
      String newDue =
      Jiffy.parseFromDateTime(newDeadline.dueDate).toLocal().toString();
      NotificationService.instance.scheduleNotification(
          id: newDeadline.notificationID!,
          warnDate: newDeadline.warnDate,
          message: "${newDeadline.name} IS DUE: $newDue",
          payload: "DEADLINE\n${newDeadline.notificationID}");
    }

    return updateDeadline(deadline: newDeadline);
  }

  Future<void> populateCalendar({required DateTime limit}) async {
    DateTime startTime = DateTime.now();
    while (startTime.isBefore(limit)) {
      List<Deadline> repeatables = await _repository.getRepeatables(now: limit);

      if (repeatables.isEmpty) {
        break;
      }
      checkRepeating(now: startTime, repeatables: repeatables);

      startTime.add(const Duration(days: 1));
    }
  }

  // This is somewhat hacky, but populateCalendar needs an early escape.
  Future<void> checkRepeating(
      {required DateTime now, List<Deadline>? repeatables}) async {
    List<Deadline> toUpdate = List.empty(growable: true);

    repeatables = repeatables ?? await _repository.getRepeatables(now: now);

    for (Deadline deadline in repeatables) {
      DateTime? nextRepeatDate = getRepeatDate(deadline: deadline);

      if (null == nextRepeatDate) {
        deadline.repeatable = false;
        toUpdate.add(deadline);
        continue;
      }

      int dueOffset = Jiffy.parseFromDateTime(deadline.dueDate)
          .diff(Jiffy.parseFromDateTime(deadline.startDate)) as int;

      int warnOffset = Jiffy.parseFromDateTime(deadline.warnDate)
          .diff(Jiffy.parseFromDateTime(deadline.startDate)) as int;

      Deadline newDeadline = deadline.copyWith(
          startDate: nextRepeatDate,
          dueDate: Jiffy
              .parseFromDateTime(nextRepeatDate)
              .add(microseconds: dueOffset)
              .dateTime,
          warnDate: Jiffy
              .parseFromDateTime(nextRepeatDate)
              .add(microseconds: warnOffset)
              .dateTime);

      newDeadline.notificationID = newDeadline.hashCode;

      // Scheduling logic.
      if (newDeadline.warnMe &&
          NotificationService.instance
              .validateWarnDate(warnDate: newDeadline.warnDate)) {
        String newDue =
        Jiffy.parseFromDateTime(newDeadline.dueDate).toLocal().toString();
        NotificationService.instance.scheduleNotification(
            id: newDeadline.notificationID!,
            warnDate: newDeadline.warnDate,
            message: "${newDeadline.name} IS DUE: $newDue",
            payload: "DEADLINE\n${newDeadline.notificationID!}");
      }

      deadline.repeatable = false;
      toUpdate.add(newDeadline);
      toUpdate.add(deadline);
    }
    updateBatch(deadlines: toUpdate);
  }

  DateTime? getCustom({required Deadline deadline}) {
    int numDays = 1;

    // Weekday is 1-indexed.
    int index = deadline.startDate.weekday % 7;
    while (true) {
      if (deadline.repeatDays[index] == true) {
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
    if (index + 1 > deadline.startDate.weekday) {
      return Jiffy
          .parseFromDateTime(deadline.startDate)
          .add(days: numDays)
          .dateTime;
    }

    Jiffy nextRepeatJiffy = Jiffy.parseFromDateTime(deadline.startDate)
        .add(days: numDays)
        .subtract(weeks: 1);

    // These should be handled within the validator.
    switch (deadline.customFreq) {
      case CustomFrequency.weekly:
        return nextRepeatJiffy
            .add(weeks: deadline.repeatSkip)
            .dateTime;
      case CustomFrequency.monthly:
        return nextRepeatJiffy
            .add(months: deadline.repeatSkip)
            .dateTime;
      case CustomFrequency.yearly:
        return nextRepeatJiffy
            .add(years: deadline.repeatSkip)
            .dateTime;
    }
  }

  Future<void> createDeadline({required Deadline deadline}) async =>
      await
      _repository.create(deadline);

  Future<List<Deadline>> searchDeadlines(
      {required String searchString}) async =>
      await
      _repository.search(searchString: searchString);

  Future<List<Deadline>> getDeadlines({int limit = 50, int offset = 0}) async =>
      await
      _repository.getRepoList(limit: limit, offset: offset);

  Future<List<Deadline>> getDeadlinesBy({required SortableView<Deadline> sorter,
    int limit = 50,
    int offset = 0}) async =>
      await
      _repository.getRepoListBy(sorter: sorter, limit: limit, offset: offset);

  Future<Deadline?> getDeadlineByID({required int id}) async =>
      await
      _repository.getByID(id: id);

  Future<List<Deadline>> getRange({DateTime? start, DateTime? end}) async =>
      await _repository.getRange(start: start, end: end);

  Future<List<Deadline>> getOverdues({int limit = 50, int offset = 0}) async =>
      await
      _repository.getOverdues(limit: limit, offset: offset);

  Future<List<Deadline>> getUpcoming({int limit = 50, int offset = 0}) async =>
      await
      _repository.getUpcoming(limit: limit, offset: offset);

  Future<List<Deadline>> mostRecent({int limit = 5}) async =>
      await
      _repository.mostRecent(limit: limit);

  Future<void> updateDeadline({required Deadline deadline}) async =>
      await
      _repository.update(deadline);

  Future<void> updateBatch({required List<Deadline> deadlines}) async =>
      await
      _repository.updateBatch(deadlines);

  Future<void> deleteDeadline({required Deadline deadline}) async =>
      await
      _repository.delete(deadline);

  Future<void> clearDeletesLocalRepo() async => await _repository.deleteLocal();

  Future<void> deleteFutures({required Deadline deadline}) async =>
      await
      _repository.deleteFutures(deleteFrom: deadline);

  Future<void> syncRepo() async => await _repository.syncRepo();

  Future<List<Deadline>> reorderDeadlines({required List<Deadline> deadlines,
    required int oldIndex,
    required int newIndex}) async {
    if (oldIndex < newIndex) {
      newIndex--;
    }
    Deadline d = deadlines.removeAt(oldIndex);
    deadlines.insert(newIndex, d);
    for (int i = 0; i < deadlines.length; i++) {
      deadlines[i].customViewIndex = i;
    }
    _repository.updateBatch(deadlines);
    return deadlines;
  }
}
