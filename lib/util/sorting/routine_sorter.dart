import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';

import '../../model/task/routine.dart';
import '../enums.dart';
import '../interfaces/sortable.dart';

part "routine_sorter.g.dart";

@Embedded(inheritance: false)
class RoutineSorter with EquatableMixin implements SortableView<Routine> {
  @override
  bool descending = false;

  @override
  @Enumerated(EnumType.ordinal)
  SortMethod sortMethod = SortMethod.none;

  RoutineSorter({this.descending = false, this.sortMethod = SortMethod.none});

  @override
  @ignore
  final List<SortMethod> sortMethods = [
    SortMethod.none,
    SortMethod.name,
    SortMethod.weight,
    SortMethod.duration
  ];

  @override
  @ignore
  List<Object?> get props => [sortMethod, descending];

  @override
  @ignore
  bool? get stringify => null;
}
