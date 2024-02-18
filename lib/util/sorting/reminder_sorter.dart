import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';

import '../../model/task/reminder.dart';
import '../enums.dart';
import '../interfaces/sortable.dart';

part "reminder_sorter.g.dart";

@Embedded(inheritance: false)
class ReminderSorter with EquatableMixin implements SortableView<Reminder> {
  @override
  bool descending = false;

  @override
  @Enumerated(EnumType.ordinal)
  SortMethod sortMethod = SortMethod.none;

  ReminderSorter({this.descending = false, this.sortMethod = SortMethod.none});

  @override
  @ignore
  final List<SortMethod> sortMethods = [
    SortMethod.none,
    SortMethod.name,
    SortMethod.due_date
  ];

  @override
  @ignore
  List<Object?> get props => [sortMethod, descending];

  @override
  @ignore
  bool? get stringify => null;
}
