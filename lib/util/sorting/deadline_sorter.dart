import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';

import '../../model/task/deadline.dart';
import '../enums.dart';
import '../interfaces/sortable.dart';

part "deadline_sorter.g.dart";

@Embedded(inheritance: false)
class DeadlineSorter with EquatableMixin implements SortableView<Deadline> {
  @override
  bool descending = false;

  @override
  @Enumerated(EnumType.ordinal)
  SortMethod sortMethod = SortMethod.none;

  DeadlineSorter({this.descending = false, this.sortMethod = SortMethod.none});

  @override
  @ignore
  final List<SortMethod> sortMethods = [
    SortMethod.none,
    SortMethod.name,
    SortMethod.due_date,
    SortMethod.priority
  ];

  @override
  @ignore
  List<Object?> get props => [sortMethod, descending];

  @override
  @ignore
  bool? get stringify => null;
}
