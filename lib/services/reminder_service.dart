import '../model/task/reminder.dart';
import '../util/interfaces/reminder_repository.dart';

class ReminderService {

  static final ReminderService _instance = ReminderService._internal();

  late ReminderRepository _repository;

  set repository(ReminderRepository repo) => _repository = repo;

  Future<void> createReminder(Reminder r) async => _repository.create(r);
  Future<void> updateReminder(Reminder r) async => _repository.update(r);
  Future<void> updateBatch(List<Reminder> reminders) async => _repository.updateBatch(reminders);
  Future<void> retry(List<Reminder> reminders) async => _repository.retry(reminders);
  Future<void> deleteReminder(Reminder r) async => _repository.delete(r);
  // TODO: Not sure abt showLoading.
  Future<void> syncRepo() async => _repository.syncRepo(showLoading: false);

  Future<List<Reminder>> getDeadlines() async => _repository.getRepoList();
  // TODO: this may need a covariant override.
  Future<List<Reminder>> getRemindersBy(Sorter<Reminder> sorter) async => _repository.getRepoListBy(sorter: sorter);

  Future<void> reorderReminders(List<Reminder> reminders, int oldIndex, int newIndex) async {
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

  ReminderService._internal();

}