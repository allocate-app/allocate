import '../model/task/reminder.dart';
import '../repositories/reminder_repo.dart';
import '../util/interfaces/reminder_repository.dart';
import '../util/interfaces/sortable.dart';

class ReminderService {

  //Default repo for now, switch as needed for testing.
  ReminderRepository _repository = ReminderRepo();

  set repository(ReminderRepository repo) => _repository = repo;

  Future<void> createReminder({required Reminder reminder}) async => _repository.create(reminder);

  Future<List<Reminder>> getReminders() async => _repository.getRepoList();
  Future<List<Reminder>> getRemindersBy(
      {required SortableView<Reminder> sorter}) async => _repository.getRepoListBy(sorter: sorter);

  Future<void> updateReminder({required Reminder reminder}) async => _repository.update(reminder);
  Future<void> updateBatch({required List<Reminder> reminders}) async => _repository.updateBatch(reminders);

  Future<void> deleteReminder({required Reminder reminder}) async => _repository.delete(reminder);

  Future<void> retry({required List<Reminder> reminders}) async => _repository.retry(reminders);

  Future<void> syncRepo() async => _repository.syncRepo();


  Future<void> reorderReminders(
      {required List<Reminder> reminders, required int oldIndex, required int newIndex}) async {
    if(oldIndex < newIndex)
    {
      newIndex--;
    }
    Reminder r = reminders.removeAt(oldIndex);
    reminders.insert(newIndex, r);
    for(int i = 0; i < reminders.length; i++)
    {
      reminders[i].customViewIndex = i;
    }
    _repository.updateBatch(reminders);
  }


}