import '../model/task/reminder.dart';
import '../util/interfaces/datacache.dart';

class ReminderDataCache implements DataCache<Reminder>
{
  static final ReminderDataCache _instance = ReminderDataCache._internal();
  static ReminderDataCache get instance => _instance;

  @override
  late Reminder current;

  @override
  List<Reminder> currents = List.empty(growable:false);

  @override
  final List<Reminder> cache = List.empty(growable: true);

  ReminderDataCache._internal();
}