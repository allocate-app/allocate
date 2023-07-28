import 'package:isar/isar.dart';

import '../../model/task/deadline.dart';
import '../enums.dart';
import '../interfaces/sortable.dart';

part "deadline_sorter.g.dart";

@embedded
class DeadlineSorter implements SortableView<Deadline> {
  @override
  bool descending = false;

  @override
  @Enumerated(EnumType.ordinal)
  SortMethod sortMethod = SortMethod.none;
  DeadlineSorter({this.descending = false, this.sortMethod = SortMethod.none});

  DeadlineSorter.fromEntity({required Map<String, dynamic> entity})
      : descending = entity["descending"] as bool,
        sortMethod = SortMethod.values[entity["sortMethod"]];

  Map<String, dynamic> toEntity() =>
      {"descending": descending, "sortMethod": sortMethod.index};

  static final List<SortMethod> sortMethods = [
    SortMethod.none,
    SortMethod.name,
    SortMethod.dueDate,
    SortMethod.priority
  ];
}
