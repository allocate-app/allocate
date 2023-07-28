import 'package:isar/isar.dart';

import '../../model/task/todo.dart';
import '../enums.dart';
import '../interfaces/sortable.dart';

part "todo_sorter.g.dart";

@embedded
class ToDoSorter implements SortableView<ToDo> {
  @override
  bool descending = false;

  @override
  @Enumerated(EnumType.ordinal)
  SortMethod sortMethod = SortMethod.none;

  ToDoSorter({this.descending = false, this.sortMethod = SortMethod.none});

  ToDoSorter.fromEntity({required Map<String, dynamic> entity})
      : descending = entity["descending"] as bool,
        sortMethod = SortMethod.values[entity["sortMethod"]];

  Map<String, dynamic> toEntity() =>
      {"descending": descending, "sortMethod": sortMethod.index};

  @override
  static final List<SortMethod> sortMethods = List.from(SortMethod.values);
}
