import '../../../../model/task/reminder.dart';
import '../function/overdue.dart';
import '../function/repeatable.dart';
import '../function/repository.dart';
import '../function/search.dart';

abstract class ReminderRepository
    implements Repository<Reminder>, Repeatable<Reminder>, Overdue<Reminder>, Search<Reminder> {}
