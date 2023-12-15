import '../../model/task/reminder.dart';
import '../enums.dart';
import '../interfaces/sortable.dart';

class ReminderSorter implements SortableView<Reminder> {
  @override
  bool descending = false;

  @override
  SortMethod sortMethod = SortMethod.none;

  ReminderSorter({this.descending = false, this.sortMethod = SortMethod.none});

  @override
  final List<SortMethod> sortMethods = [
    SortMethod.none,
    SortMethod.name,
    SortMethod.due_date
  ];
}
