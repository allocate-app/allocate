import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';

import '../../util/constants.dart';
import '../../util/interfaces/copyable.dart';

part "subtask.g.dart";

@Collection(inheritance: false)
class Subtask
    with EquatableMixin
    implements Copyable<Subtask>, Comparable<Subtask> {
  @Index()
  Id id = Constants.generateID();
  @Index()
  String name;
  @Index()
  bool completed;
  int weight;
  @Index()
  int? taskID;
  @Index()
  int customViewIndex;
  @Index()
  bool isSynced = false;
  @Index()
  bool toDelete = false;

  @Index()
  DateTime lastUpdated;

  Subtask(
      {this.name = "",
      this.customViewIndex = -1,
      this.weight = 0,
      this.completed = false,
      this.taskID,
      required this.lastUpdated});

  Subtask.fromEntity({required Map<String, dynamic> entity})
      : id = entity["id"] as int,
        name = entity["name"] as String,
        completed = entity["completed"] as bool,
        weight = entity["weight"] as int,
        taskID = entity["taskID"] as int?,
        lastUpdated = DateTime.parse(entity["lastUpdated"]),
        isSynced = true,
        toDelete = false,
        customViewIndex = entity["customViewIndex"] as int;

  Map<String, dynamic> toEntity() => {
        "id": id,
        "taskID": taskID,
        "name": name,
        "completed": completed,
        "weight": weight,
        "customViewIndex": customViewIndex,
        "lastUpdated": lastUpdated.toIso8601String(),
      };

  @override
  int compareTo(Subtask st2) => name.compareTo(st2.name);

  @override
  Subtask copy() => Subtask(
        name: name,
        taskID: taskID,
        weight: weight,
        completed: completed,
        customViewIndex: customViewIndex,
        lastUpdated: lastUpdated,
      );

  @override
  Subtask copyWith(
          {String? name,
          int? weight,
          int? taskID,
          bool? completed,
          int? customViewIndex,
          DateTime? lastUpdated}) =>
      Subtask(
          name: name ?? this.name,
          weight: weight ?? this.weight,
          taskID: taskID ?? this.taskID,
          completed: completed ?? this.completed,
          customViewIndex: customViewIndex ?? this.customViewIndex,
          lastUpdated: lastUpdated ?? this.lastUpdated);

  @ignore
  @override
  List<Object?> get props => [id];

  @override
  String toString() =>
      "SubTask(id: $id, taskID: $taskID, name: $name, weight: $weight, completed: $completed)";
}
