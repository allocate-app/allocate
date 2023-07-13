import '../../../model/task/reminder.dart';
import '../../enums.dart';
import 'sortable.dart';

class ReminderSorter implements SortableView<Reminder> {
  @override
  bool descending = false;

  @override
  SortMethod sortMethod = SortMethod.none;

  @override
  static final List<SortMethod> sortMethods = [
    SortMethod.none,
    SortMethod.name,
    SortMethod.dueDate
  ];
}