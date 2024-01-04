import '../model/task/reminder.dart';
import '../repositories/reminder_repo.dart';
import '../util/constants.dart';
import '../util/enums.dart';
import '../util/interfaces/repository/model/reminder_repository.dart';
import '../util/interfaces/sortable.dart';

class ReminderService {
  ReminderRepository _repository = ReminderRepo();

  set repository(ReminderRepository repo) => _repository = repo;

  int getDateTimeDayOffset({required DateTime start, required DateTime end}) {
    start = DateTime.utc(start.year, start.month, start.day, start.hour,
        start.minute, start.second, start.millisecond, start.microsecond);
    end = DateTime.utc(end.year, end.month, end.day, end.hour, end.minute,
        end.second, end.millisecond, end.microsecond);
    return end.difference(start).inDays;
  }

  DateTime? getRepeatDate({required Reminder reminder}) =>
      switch (reminder.frequency) {
        (Frequency.daily) => reminder.dueDate!.copyWith(
            day: reminder.dueDate!.day + reminder.repeatSkip,
            hour: reminder.dueDate!.hour,
            minute: reminder.dueDate!.minute),
        (Frequency.weekly) => reminder.dueDate!.copyWith(
            day: reminder.dueDate!.day + (reminder.repeatSkip * 7),
            hour: reminder.dueDate!.hour,
            minute: reminder.dueDate!.minute),
        (Frequency.monthly) => reminder.dueDate!.copyWith(
            month: reminder.dueDate!.month + reminder.repeatSkip,
            hour: reminder.dueDate!.hour,
            minute: reminder.dueDate!.minute),
        (Frequency.yearly) => reminder.dueDate!.copyWith(
            year: reminder.dueDate!.year + reminder.repeatSkip,
            hour: reminder.dueDate!.hour,
            minute: reminder.dueDate!.minute),
        (Frequency.custom) => getCustom(reminder: reminder),
        //Once should never repeat -> fixing asynchronously in case validation fails.
        (Frequency.once) => null,
      };

  Future<void> nextRepeatable({required Reminder reminder}) async {
    DateTime? nextRepeatDate = getRepeatDate(reminder: reminder);

    if (null == nextRepeatDate) {
      return;
    }

    Reminder newReminder = reminder.copyWith(
      dueDate: nextRepeatDate,
      lastUpdated: DateTime.now(),
    );

    newReminder.notificationID = Constants.generateID();
    reminder.repeatable = false;
    await _repository.updateBatch([reminder, newReminder]);
  }

  // Future<void> populateCalendar({required DateTime limit}) async {
  //   DateTime startTime = DateTime.now();
  //   while (startTime.isBefore(limit)) {
  //     List<Reminder> repeatables =
  //         await _repository.getRepeatables(now: startTime);
  //
  //     await checkRepeating(now: startTime, repeatables: repeatables)
  //         .whenComplete(() {
  //       startTime = startTime.copyWith(day: startTime.day + 1);
  //     });
  //   }
  // }
  //
  // Future<void> checkRepeating(
  //     {required DateTime now, List<Reminder>? repeatables}) async {
  //   List<Reminder> toUpdate = List.empty(growable: true);
  //
  //   repeatables = repeatables ?? await _repository.getRepeatables(now: now);
  //
  //   for (Reminder reminder in repeatables) {
  //     DateTime? nextRepeatDate = getRepeatDate(reminder: reminder);
  //
  //     if (null == nextRepeatDate) {
  //       reminder.repeatable = false;
  //       toUpdate.add(reminder);
  //       continue;
  //     }
  //
  //     Reminder newReminder = reminder.copyWith(
  //       dueDate: nextRepeatDate,
  //       lastUpdated: DateTime.now(),
  //     );
  //
  //     newReminder.notificationID = Constants.generateID();
  //
  //     reminder.repeatable = false;
  //     toUpdate.add(newReminder);
  //     toUpdate.add(reminder);
  //   }
  //   await _repository.updateBatch(toUpdate);
  // }

  DateTime? getCustom({required Reminder reminder}) {
    int start = reminder.dueDate!.weekday - 1;
    int end = 0;
    if (start + 1 != 7) {
      end = reminder.repeatDays.indexOf(true, start + 1);
      if (end > 0) {
        return reminder.dueDate!.copyWith(
            day: reminder.dueDate!.day + (end - start),
            hour: reminder.dueDate!.hour,
            minute: reminder.dueDate!.minute);
      }
    }
    end = reminder.repeatDays.indexOf(true);
    int offset = end - start;
    DateTime nextDate =
        reminder.dueDate!.copyWith(day: reminder.dueDate!.day + offset);

    nextDate = nextDate.copyWith(
        day: nextDate.day + (7 * reminder.repeatSkip),
        hour: reminder.dueDate!.hour,
        minute: reminder.dueDate!.minute,
        second: 0,
        millisecond: 0,
        microsecond: 0);

    // This is to compensate for leap-years and 30/31 day issues
    int edgeOffset = end - nextDate.weekday + 1;
    nextDate = nextDate.copyWith(day: nextDate.day + edgeOffset);

    return nextDate;
  }

  Future<Reminder> createReminder({required Reminder reminder}) async =>
      await _repository.create(reminder);

  Future<List<Reminder>> searchReminders(
          {required String searchString}) async =>
      await _repository.search(searchString: searchString);

  Future<List<Reminder>> getReminders({int limit = 50, int offset = 0}) async =>
      await _repository.getRepoList(limit: limit, offset: offset);

  Future<List<Reminder>> getRemindersBy(
          {required SortableView<Reminder> sorter,
          int limit = 50,
          int offset = 0}) async =>
      await _repository.getRepoListBy(
          sorter: sorter, limit: limit, offset: offset);

  Future<Reminder?> getReminderByID({int? id}) async =>
      (null != id) ? await _repository.getByID(id: id) : null;

  Future<List<Reminder>> getRange({DateTime? start, DateTime? end}) async =>
      await _repository.getRange(start: start, end: end);

  Future<List<Reminder>> mostRecent({int limit = 5}) async =>
      await _repository.mostRecent(limit: limit);

  Future<List<Reminder>> getOverdues({int limit = 50, int offset = 0}) async =>
      await _repository.getOverdues(limit: limit, offset: offset);

  Future<List<Reminder>> getUpcoming({int limit = 50, int offset = 0}) async =>
      await _repository.getUpcoming(limit: limit, offset: offset);

  Future<Reminder> updateReminder({required Reminder reminder}) async =>
      await _repository.update(reminder);

  Future<void> updateBatch({required List<Reminder> reminders}) async =>
      await _repository.updateBatch(reminders);

  Future<void> deleteReminder({required Reminder reminder}) async =>
      await _repository.delete(reminder);

  Future<void> clearDeletesLocalRepo() async => await _repository.deleteLocal();

  Future<List<int>> deleteFutures({required Reminder reminder}) async =>
      await _repository.deleteFutures(deleteFrom: reminder);

  Future<void> syncRepo() async => await _repository.syncRepo();

  Future<List<Reminder>> reorderReminders(
      {required List<Reminder> reminders,
      required int oldIndex,
      required int newIndex}) async {
    if (oldIndex < newIndex) {
      newIndex--;
    }
    Reminder r = reminders.removeAt(oldIndex);
    reminders.insert(newIndex, r);
    for (int i = 0; i < reminders.length; i++) {
      reminders[i].customViewIndex = i;
    }
    await _repository.updateBatch(reminders);
    return reminders;
  }
}
