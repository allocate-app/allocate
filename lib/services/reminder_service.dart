import '../model/task/reminder.dart';
import '../repositories/reminder_repo.dart';
import '../util/interfaces/repository/model/reminder_repository.dart';
import '../util/interfaces/sortable.dart';

class ReminderService {
  //Default repo for now, switch as needed for testing.
  ReminderRepository _repository = ReminderRepo();

  set repository(ReminderRepository repo) => _repository = repo;

  // For now, consider shelving repeating reminders. Other models are more appropriate.
  // DateTime? getRepeatDate({required Reminder reminder}) => switch (reminder.frequency) {
  //       (Frequency.daily) =>
  //         Jiffy.parseFromDateTime(reminder.startDate).add(days: reminder.repeatSkip).dateTime,
  //       (Frequency.weekly) =>
  //         Jiffy.parseFromDateTime(reminder.startDate).add(weeks: reminder.repeatSkip).dateTime,
  //       (Frequency.monthly) =>
  //         Jiffy.parseFromDateTime(reminder.startDate).add(months: reminder.repeatSkip).dateTime,
  //       (Frequency.yearly) =>
  //         Jiffy.parseFromDateTime(reminder.startDate).add(years: reminder.repeatSkip).dateTime,
  //       (Frequency.custom) => getCustom(reminder: reminder),
  //       //Once should never repeat -> fixing asynchronously in case validation fails.
  //       (Frequency.once) => null,
  //     };
  //
  // Future<void> nextRepeatable({required Reminder reminder}) async {
  //   DateTime? nextRepeatDate = getRepeatDate(reminder: reminder);
  //
  //   if (null == nextRepeatDate) {
  //     return;
  //   }
  //
  //   int dueOffset = Jiffy.parseFromDateTime(reminder.dueDate)
  //       .diff(Jiffy.parseFromDateTime(reminder.startDate)) as int;
  //
  //   int warnOffset = Jiffy.parseFromDateTime(reminder.warnDate)
  //       .diff(Jiffy.parseFromDateTime(reminder.startDate)) as int;
  //
  //   Reminder newReminder = reminder.copyWith(
  //       startDate: nextRepeatDate,
  //       dueDate: Jiffy.parseFromDateTime(nextRepeatDate).add(microseconds: dueOffset).dateTime,
  //       warnDate: Jiffy.parseFromDateTime(nextRepeatDate).add(microseconds: warnOffset).dateTime);
  //
  //   String newDue = Jiffy.parseFromDateTime(newReminder.dueDate).toLocal().toString();
  //
  //   newReminder.notificationID = newReminder.hashCode;
  //   NotificationService.instance.scheduleNotification(
  //       id: newReminder.notificationID!,
  //       warnDate: newReminder.warnDate,
  //       message: "${newReminder.name} IS DUE: $newDue",
  //       payload: "REMINDER\n${newReminder.notificationID!}");
  //
  //   return updateReminder(reminder: newReminder);
  // }
  //
  // // TODO: this could be repeated.
  // Future<void> populateCalendar({required DateTime limit}) async {
  //   DateTime startTime = DateTime.now();
  //   while (startTime.isBefore(limit)) {
  //     List<Reminder> repeatables = await _repository.getRepeatables(now: limit);
  //
  //     if (repeatables.isEmpty) {
  //       break;
  //     }
  //     checkRepeating(now: startTime, repeatables: repeatables);
  //
  //     startTime.add(const Duration(days: 1));
  //   }
  // }
  //
  // // This is somewhat hacky, but populateCalendar needs an early escape.
  // Future<void> checkRepeating({required DateTime now, List<Reminder>? repeatables}) async {
  //   List<Reminder> toUpdate = List.empty(growable: true);
  //
  //   repeatables = repeatables ?? await _repository.getRepeatables(now: now);
  //
  //   for (Reminder reminder in repeatables) {
  //     // This needs to be factored out into its own method.
  //     DateTime? nextRepeatDate = getRepeatDate(reminder: reminder);
  //
  //     if (null == nextRepeatDate) {
  //       reminder.repeatable = false;
  //       continue;
  //     }
  //
  //     int dueOffset = Jiffy.parseFromDateTime(reminder.dueDate)
  //         .diff(Jiffy.parseFromDateTime(reminder.startDate)) as int;
  //
  //     int warnOffset = Jiffy.parseFromDateTime(reminder.warnDate)
  //         .diff(Jiffy.parseFromDateTime(reminder.startDate)) as int;
  //
  //     Reminder newReminder = reminder.copyWith(
  //         startDate: nextRepeatDate,
  //         dueDate: Jiffy.parseFromDateTime(nextRepeatDate).add(microseconds: dueOffset).dateTime,
  //         warnDate: Jiffy.parseFromDateTime(nextRepeatDate).add(microseconds: warnOffset).dateTime);
  //
  //     newReminder.notificationID = newReminder.hashCode;
  //
  //     String newDue = Jiffy.parseFromDateTime(newReminder.dueDate).toLocal().toString();
  //     NotificationService.instance.scheduleNotification(
  //         id: newReminder.notificationID!,
  //         warnDate: newReminder.warnDate,
  //         message: "${newReminder.name} is DUE: $newDue ",
  //         payload: "REMINDER\n${newReminder.notificationID!}");
  //
  //     reminder.repeatable = false;
  //     toUpdate.add(newReminder);
  //     toUpdate.add(reminder);
  //   }
  //   updateBatch(reminders: toUpdate);
  // }
  //
  // DateTime? getCustom({required Reminder reminder}) {
  //   int numDays = 1;
  //
  //   // Weekday is 1-indexed.
  //   int index = reminder.startDate.weekday % 7;
  //   while (true) {
  //     if (reminder.repeatDays[index] = true) {
  //       break;
  //     }
  //     numDays += 1;
  //     index = (index + 1) % 7;
  //     // This will only happen if there are no repeat days in the list.
  //     // This is an error and should be caught during validation.
  //     // If it does somehow happen, assume it is once repeatable and thus repeated.
  //     if (numDays > 7) {
  //       log("Repeat Error: no repeating dates.");
  //       return null;
  //     }
  //   }
  //
  //   // ie. if it is within the same week.
  //   if (index + 1 > reminder.startDate.weekday) {
  //     return Jiffy.parseFromDateTime(reminder.startDate).add(days: numDays).dateTime;
  //   }
  //
  //   Jiffy nextRepeatJiffy =
  //       Jiffy.parseFromDateTime(reminder.startDate).add(days: numDays).subtract(weeks: 1);
  //
  //   // These should be handled within the validator.
  //   switch (reminder.customFreq) {
  //     case CustomFrequency.weekly:
  //       return nextRepeatJiffy.add(weeks: reminder.repeatSkip).dateTime;
  //     case CustomFrequency.monthly:
  //       return nextRepeatJiffy.add(months: reminder.repeatSkip).dateTime;
  //     case CustomFrequency.yearly:
  //       return nextRepeatJiffy.add(years: reminder.repeatSkip).dateTime;
  //   }
  // }

  Future<void> createReminder({required Reminder reminder}) async =>
      _repository.create(reminder);

  Future<List<Reminder>> searchReminders(
          {required String searchString}) async =>
      _repository.search(searchString: searchString);

  Future<List<Reminder>> getReminders({int limit = 50, int offset = 0}) async =>
      _repository.getRepoList(limit: limit, offset: offset);

  Future<List<Reminder>> getRemindersBy(
          {required SortableView<Reminder> sorter,
          int limit = 50,
          int offset = 0}) async =>
      _repository.getRepoListBy(sorter: sorter, limit: limit, offset: offset);

  Future<Reminder?> getReminderByID({required int id}) async =>
      _repository.getByID(id: id);

  Future<List<Reminder>> mostRecent({int limit = 5}) async =>
      _repository.mostRecent(limit: limit);

  Future<List<Reminder>> getOverdues({int limit = 50, int offset = 0}) async =>
      _repository.getOverdues(limit: limit, offset: offset);

  Future<List<Reminder>> getUpcoming({int limit = 50, int offset = 0}) async =>
      _repository.getUpcoming(limit: limit, offset: offset);

  Future<void> updateReminder({required Reminder reminder}) async =>
      _repository.update(reminder);

  Future<void> updateBatch({required List<Reminder> reminders}) async =>
      _repository.updateBatch(reminders);

  Future<void> deleteReminder({required Reminder reminder}) async =>
      _repository.delete(reminder);

  Future<void> clearDeletesLocalRepo() async => _repository.deleteLocal();

  // Future<void> deleteFutures({required Reminder reminder}) async =>
  //     _repository.deleteFutures(deleteFrom: reminder);

  Future<void> syncRepo() async => _repository.syncRepo();

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
    _repository.updateBatch(reminders);
    return reminders;
  }
}
