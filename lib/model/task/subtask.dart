import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';

import '../../util/constants.dart';
import '../../util/enums.dart';
import '../../util/interfaces/copyable.dart';
import '../../util/interfaces/i_model.dart';

part "subtask.g.dart";

@Collection(inheritance: false)
class Subtask
    with EquatableMixin
    implements Copyable<Subtask>, Comparable<Subtask>, IModel {
  @override
  @Index()
  late Id id;

  @override
  @ignore
  ModelType modelType = ModelType.subtask;

  @override
  @ignore
  Fade fade = Fade.none;

  @override
  @Index()
  String name;
  @Index()
  bool completed;
  int weight;
  @Index()
  int? taskID;
  int customViewIndex;
  @override
  @Index()
  late bool isSynced = false;
  @override
  @Index()
  late bool toDelete = false;

  @override
  DateTime lastUpdated;

  Subtask(
      {required this.id,
      this.name = "",
      this.customViewIndex = -1,
      this.weight = 0,
      this.completed = false,
      this.taskID,
      this.isSynced = false,
      this.toDelete = false,
      required this.lastUpdated});

  Subtask.fromEntity({required Map<String, dynamic> entity})
      : id = entity["id"] as int,
        customViewIndex = entity["customViewIndex"] as int,
        name = entity["name"] as String,
        completed = entity["completed"] as bool,
        weight = entity["weight"] as int,
        taskID = entity["taskID"] as int?,
        isSynced = true,
        toDelete = entity["toDelete"] as bool,
        lastUpdated =
            DateTime.tryParse(entity["lastUpdated"]) ?? Constants.today;

  Map<String, dynamic> toEntity() => {
        "id": id,
        "taskID": taskID,
        "name": name,
        "completed": completed,
        "weight": weight,
        "customViewIndex": customViewIndex,
        "toDelete": toDelete,
        "lastUpdated": lastUpdated.toIso8601String(),
      };

  @override
  int compareTo(Subtask st2) => name.compareTo(st2.name);

  @override
  Subtask copy() => Subtask(
        id: Constants.generateID(),
        name: name,
        taskID: taskID,
        weight: weight,
        completed: completed,
        customViewIndex: customViewIndex,
        lastUpdated: lastUpdated,
        isSynced: isSynced,
        toDelete: toDelete,
      );

  @override
  Subtask copyWith(
          {int? id,
          String? name,
          int? weight,
          int? taskID,
          bool? completed,
          int? customViewIndex,
          bool? isSynced,
          bool? toDelete,
          DateTime? lastUpdated}) =>
      Subtask(
          id: id ?? Constants.generateID(),
          name: name ?? this.name,
          weight: weight ?? this.weight,
          taskID: taskID ?? this.taskID,
          completed: completed ?? this.completed,
          customViewIndex: customViewIndex ?? this.customViewIndex,
          isSynced: isSynced ?? this.isSynced,
          toDelete: toDelete ?? this.toDelete,
          lastUpdated: lastUpdated ?? this.lastUpdated);

  @ignore
  @override
  List<Object?> get props => [id];

  @override
  String toString() =>
      "SubTask(id: $id, taskID: $taskID, name: $name, weight: $weight, completed: $completed)";
}
