import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';

import '../../model/task/todo.dart';
import '../enums.dart';
import '../interfaces/sortable.dart';

part "todo_sorter.g.dart";

@Embedded(inheritance: false)
class ToDoSorter with EquatableMixin implements SortableView<ToDo> {
  @override
  bool descending = false;

  @override
  @Enumerated(EnumType.ordinal)
  SortMethod sortMethod = SortMethod.none;

  ToDoSorter({this.descending = false, this.sortMethod = SortMethod.none});

  @override
  @ignore
  final List<SortMethod> sortMethods = List.from(SortMethod.values);

  @override
  @ignore
  List<Object?> get props => [sortMethod, descending];

  @override
  @ignore
  bool? get stringify => null;
}
