import '../../../../model/task/reminder.dart';
import '../function/date_range.dart';
import '../function/overdue.dart';
import '../function/repository.dart';
import '../function/search.dart';
import '../function/upcoming.dart';

// TODO: Consider re-implementing repeatable.
abstract class ReminderRepository
    implements
        Repository<Reminder>,
        Overdue<Reminder>,
        Upcoming<Reminder>,
        DateRange<Reminder>,
        Search<Reminder> {}
