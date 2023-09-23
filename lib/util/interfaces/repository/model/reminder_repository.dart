import '../../../../model/task/reminder.dart';
import '../function/date_range.dart';
import '../function/local_notifications.dart';
import '../function/overdue.dart';
import '../function/repeatable.dart';
import '../function/repository.dart';
import '../function/search.dart';
import '../function/upcoming.dart';

abstract class ReminderRepository
    implements
        Repository<Reminder>,
        Overdue<Reminder>,
        Upcoming<Reminder>,
        DateRange<Reminder>,
        Repeatable<Reminder>,
        LocalNotifications<Reminder>,
        Search<Reminder> {}
