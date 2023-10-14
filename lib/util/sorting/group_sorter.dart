import 'package:isar/isar.dart';

import '../../model/task/group.dart';
import '../enums.dart';
import '../interfaces/sortable.dart';

part "group_sorter.g.dart";

@embedded
class GroupSorter implements SortableView<Group> {
  @override
  bool descending;

  @override
  @Enumerated(EnumType.ordinal)
  SortMethod sortMethod;

  GroupSorter({this.descending = false, this.sortMethod = SortMethod.none});

  GroupSorter.fromEntity({required Map<String, dynamic> entity})
      : descending = entity["descending"] as bool,
        sortMethod = SortMethod.values[entity["sortMethod"]];

  Map<String, dynamic> toEntity() =>
      {"descending": descending, "sortMethod": sortMethod.index};

  @override
  final List<SortMethod> sortMethods = [
    SortMethod.none,
    SortMethod.name,
  ];
}
