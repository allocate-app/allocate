import 'package:flutter/foundation.dart';

import '../model/task/reminder.dart';
import '../services/reminder_service.dart';
import '../util/enums.dart';
import '../util/sorters/reminder_sorter.dart';

class ReminderProvider extends ChangeNotifier {
  ReminderProvider();

  final ReminderService _reminderService = ReminderService();

  late Reminder curReminder;

  late List<Reminder> reminders;

  List<Reminder> failCache = List.empty(growable: true);

  ReminderSorter sorter = ReminderSorter();

  SortMethod get sortMethod => sorter.sortMethod;
  set sortMethod(SortMethod method)
  {
    if(method == sorter.sortMethod)
    {
      sorter.descending = !sorter.descending;
    }
    else
    {
      sorter.sortMethod = method;
      sorter.descending = false;
    }
    notifyListeners();
  }

  bool get descending => sorter.descending;

  List<SortMethod> get sortMethods => ReminderSorter.sortMethods;




}