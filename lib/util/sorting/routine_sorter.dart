import 'package:isar/isar.dart';

import '../../../model/task/routine.dart';
import '../enums.dart';
import '../interfaces/sortable.dart';

part "routine_sorter.g.dart"

@embedded
class RoutineSorter implements SortableView<Routine> {
  @override
  bool descending = false;

  @override
  SortMethod sortMethod = SortMethod.none;
  RoutineSorter({this.descending = false, this.sortMethod = SortMethod.none});

  RoutineSorter.fromEntity({required Map<String, dynamic> entity})
      : descending = entity["descending"] as bool,
        sortMethod = SortMethod.values[entity["sortMethod"]];

  Map<String, dynamic> toEntity() =>
      {"descending": descending, "sortMethod": sortMethod.index};

  static final List<SortMethod> sortMethods = [
    SortMethod.none,
    SortMethod.name,
    SortMethod.weight,
    SortMethod.duration
  ];
}
