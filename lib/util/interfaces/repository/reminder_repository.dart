import '../../../model/task/reminder.dart';
import 'repository.dart';

abstract class ReminderRepository implements Repository<Reminder> {
  Future<List<Reminder>> getRepeatables({DateTime? now});
  Future<void> deleteFutures({required Reminder reminder});
}
