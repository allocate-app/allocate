import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';

import '../../util/interfaces/copyable.dart';

part "subtask.g.dart";

@embedded
class SubTask
    with EquatableMixin
    implements Copyable<SubTask>, Comparable<SubTask> {
  String name;
  bool completed = false;
  int weight;
  SubTask({required this.name, this.weight = 0});

  SubTask.fromEntity({required Map<String, dynamic> entity})
      : name = entity["name"] as String,
        completed = entity["completed"] as bool,
        weight = entity["weight"] as int;

  Map<String, dynamic> toEntity() => {
        "name": name,
        "completed": completed,
        "weight": weight,
      };

  @override
  int compareTo(SubTask st2) => name.compareTo(st2.name);

  // Instead this might need to implement a serializable interface. Ditto for large tasks
  @override
  SubTask copy() => SubTask(name: name, weight: weight);
  @override
  SubTask copyWith({String? name, int? weight}) =>
      SubTask(name: name ?? this.name, weight: weight ?? this.weight);

  @override
  List<Object?> get props => [name, completed, weight];
}
