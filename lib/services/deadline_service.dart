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

  int getDateTimeDayOffset({required DateTime start, required DateTime end}) {
    start = DateTime.utc(start.year, start.month, start.day, start.hour,
        start.minute, start.second, start.millisecond, start.microsecond);
    end = DateTime.utc(end.year, end.month, end.day, end.hour, end.minute,
        end.second, end.millisecond, end.microsecond);
    return end.difference(start).inDays;
  }

  DateTime? getRepeatDate({required Deadline deadline}) =>
      switch (deadline.frequency) {
        (Frequency.daily) => deadline.startDate
            .copyWith(day: deadline.startDate.day + deadline.repeatSkip),
        (Frequency.weekly) => deadline.startDate.copyWith(
            day: deadline.startDate.day + (deadline.repeatSkip * 7),
            hour: deadline.startDate.hour,
            minute: deadline.startDate.minute),
        (Frequency.monthly) => deadline.startDate.copyWith(
            month: deadline.startDate.month + deadline.repeatSkip,
            hour: deadline.startDate.hour,
            minute: deadline.startDate.minute),
        (Frequency.yearly) => deadline.startDate.copyWith(
            year: deadline.startDate.year + deadline.repeatSkip,
            hour: deadline.startDate.hour,
            minute: deadline.startDate.minute),
        (Frequency.custom) => getCustom(deadline: deadline),
        //Once should never repeat -> fixing asynchronously in case validation fails.
        (Frequency.once) => null,
      };

  Future<void> nextRepeatable({required Deadline deadline}) async {
    DateTime? nextRepeatDate = getRepeatDate(deadline: deadline);

    if (null == nextRepeatDate) {
      return;
    }

    int dueOffset =
        getDateTimeDayOffset(start: deadline.startDate, end: deadline.dueDate);

    int warnOffset =
        getDateTimeDayOffset(start: deadline.startDate, end: deadline.warnDate);

    Deadline newDeadline = deadline.copyWith(
      startDate: nextRepeatDate,
      dueDate: nextRepeatDate.copyWith(
          day: nextRepeatDate.day + dueOffset,
          hour: deadline.dueDate.hour,
          minute: deadline.dueDate.minute),
      warnDate: nextRepeatDate.copyWith(
          day: nextRepeatDate.day + warnOffset,
          hour: deadline.warnDate.hour,
          minute: deadline.warnDate.minute),
    );

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

    return await updateDeadline(deadline: newDeadline);
  }

  Future<void> populateCalendar({required DateTime limit}) async {
    DateTime startTime = DateTime.now();
    while (startTime.isBefore(limit)) {
      List<Deadline> repeatables =
          await _repository.getRepeatables(now: startTime);

      await checkRepeating(now: startTime, repeatables: repeatables)
          .whenComplete(() {
        startTime = startTime.copyWith(day: startTime.day + 1);
      });
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

      int dueOffset = getDateTimeDayOffset(
          start: deadline.startDate, end: deadline.dueDate);

      int warnOffset = getDateTimeDayOffset(
          start: deadline.startDate, end: deadline.warnDate);

      Deadline newDeadline = deadline.copyWith(
          startDate: nextRepeatDate,
          dueDate: nextRepeatDate.copyWith(
              day: nextRepeatDate.day + dueOffset,
              hour: deadline.dueDate.hour,
              minute: deadline.dueDate.minute),
          warnDate: nextRepeatDate.copyWith(
              day: nextRepeatDate.day + warnOffset,
              hour: deadline.warnDate.hour,
              minute: deadline.warnDate.minute));

      newDeadline.notificationID = newDeadline.hashCode;

      // Scheduling logic.
      if (newDeadline.warnMe &&
          NotificationService.instance
              .validateWarnDate(warnDate: newDeadline.warnDate)) {
        String newDue =
            Jiffy.parseFromDateTime(newDeadline.dueDate).toLocal().toString();
        await NotificationService.instance.scheduleNotification(
            id: newDeadline.notificationID!,
            warnDate: newDeadline.warnDate,
            message: "${newDeadline.name} IS DUE: $newDue",
            payload: "DEADLINE\n${newDeadline.notificationID!}");
      }

      deadline.repeatable = false;
      toUpdate.add(newDeadline);
      toUpdate.add(deadline);
    }
    await updateBatch(deadlines: toUpdate);
  }

  DateTime? getCustom({required Deadline deadline}) {
    int start = deadline.startDate.weekday - 1;
    int end = 0;
    if (start + 1 != 7) {
      end = deadline.repeatDays.indexOf(true, start + 1);
      if (end > 0) {
        return deadline.startDate.copyWith(
            day: deadline.startDate.day + (end - start),
            hour: deadline.startDate.hour,
            minute: deadline.startDate.minute);
      }
    }
    end = deadline.repeatDays.indexOf(true);
    int offset = end - start;
    DateTime nextDate =
        deadline.startDate.copyWith(day: deadline.startDate.day + offset);

    nextDate = nextDate.copyWith(
        day: nextDate.day + (7 * deadline.repeatSkip),
        hour: deadline.startDate.hour,
        minute: deadline.startDate.minute,
        second: 0,
        millisecond: 0,
        microsecond: 0);

    // This is to compensate for leap-years and 30/31 day issues
    int edgeOffset = end - nextDate.weekday + 1;
    nextDate = nextDate.copyWith(day: nextDate.day + edgeOffset);

    return nextDate;
  }

  Future<void> createDeadline({required Deadline deadline}) async =>
      await _repository.create(deadline);

  Future<List<Deadline>> searchDeadlines(
          {required String searchString}) async =>
      await _repository.search(searchString: searchString);

  Future<List<Deadline>> getDeadlines({int limit = 50, int offset = 0}) async =>
      await _repository.getRepoList(limit: limit, offset: offset);

  Future<List<Deadline>> getDeadlinesBy(
          {required SortableView<Deadline> sorter,
          int limit = 50,
          int offset = 0}) async =>
      await _repository.getRepoListBy(
          sorter: sorter, limit: limit, offset: offset);

  Future<Deadline?> getDeadlineByID({required int id}) async =>
      await _repository.getByID(id: id);

  Future<List<Deadline>> getRange({DateTime? start, DateTime? end}) async =>
      await _repository.getRange(start: start, end: end);

  Future<List<Deadline>> getOverdues({int limit = 50, int offset = 0}) async =>
      await _repository.getOverdues(limit: limit, offset: offset);

  Future<List<Deadline>> getUpcoming({int limit = 50, int offset = 0}) async =>
      await _repository.getUpcoming(limit: limit, offset: offset);

  Future<List<Deadline>> mostRecent({int limit = 5}) async =>
      await _repository.mostRecent(limit: limit);

  Future<void> updateDeadline({required Deadline deadline}) async =>
      await _repository.update(deadline);

  Future<void> updateBatch({required List<Deadline> deadlines}) async =>
      await _repository.updateBatch(deadlines);

  Future<void> deleteDeadline({required Deadline deadline}) async =>
      await _repository.delete(deadline);

  Future<void> clearDeletesLocalRepo() async => await _repository.deleteLocal();

  Future<List<Deadline>> deleteFutures({required Deadline deadline}) async =>
      await _repository.deleteFutures(deleteFrom: deadline);

  Future<void> syncRepo() async => await _repository.syncRepo();

  Future<List<Deadline>> reorderDeadlines(
      {required List<Deadline> deadlines,
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
    await _repository.updateBatch(deadlines);
    return deadlines;
  }
}
