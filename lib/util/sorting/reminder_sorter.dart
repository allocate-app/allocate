import 'package:isar/isar.dart';

import '../../model/task/reminder.dart';
import '../enums.dart';
import '../interfaces/sortable.dart';

part "reminder_sorter.g.dart";

@embedded
class ReminderSorter implements SortableView<Reminder> {
  @override
  bool descending = false;

  @override
  @Enumerated(EnumType.ordinal)
  SortMethod sortMethod = SortMethod.none;

  ReminderSorter({this.descending = false, this.sortMethod = SortMethod.none});

  ReminderSorter.fromEntity({required Map<String, dynamic> entity})
      : descending = entity["descending"] as bool,
        sortMethod = SortMethod.values[entity["sortMethod"]];

  Map<String, dynamic> toEntity() =>
      {"descending": descending, "sortMethod": sortMethod.index};

  @override
  final List<SortMethod> sortMethods = [
    SortMethod.none,
    SortMethod.name,
    SortMethod.due_date
  ];
}
