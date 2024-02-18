import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';

import '../../model/task/group.dart';
import '../enums.dart';
import '../interfaces/sortable.dart';

part "group_sorter.g.dart";

@Embedded(inheritance: false)
class GroupSorter with EquatableMixin implements SortableView<Group> {
  @override
  bool descending;

  @override
  @Enumerated(EnumType.ordinal)
  SortMethod sortMethod;

  GroupSorter({this.descending = false, this.sortMethod = SortMethod.none});

  @override
  @ignore
  final List<SortMethod> sortMethods = [
    SortMethod.none,
    SortMethod.name,
  ];

  @override
  @ignore
  List<Object?> get props => [sortMethod, descending];

  @override
  @ignore
  bool? get stringify => null;
}
