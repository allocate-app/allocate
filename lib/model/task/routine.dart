import "package:equatable/equatable.dart";
import "package:isar/isar.dart";

import "../../util/constants.dart";
import "../../util/enums.dart";
import "../../util/interfaces/copyable.dart";
import "../../util/interfaces/i_model.dart";
import "subtask.dart";

part "routine.g.dart";

@Collection(inheritance: false)
class Routine with EquatableMixin implements Copyable<Routine>, IModel {
  @override
  @ignore
  ModelType modelType = ModelType.routine;

  @override
  @ignore
  Fade fade = Fade.none;

  @override
  @Index()
  late Id id;

  @override
  @Index()
  String name;

  late int weight;
  late int expectedDuration;
  late int realDuration;

  @ignore
  late List<Subtask> subtasks;

  late int customViewIndex;

  @override
  @Index()
  late bool isSynced;

  @override
  @Index()
  late bool toDelete;

  @override
  DateTime lastUpdated;

  Routine(
      {required this.id,
      this.customViewIndex = -1,
      required this.name,
      this.weight = 0,
      this.expectedDuration = 0,
      this.realDuration = 0,
      this.subtasks = const <Subtask>[],
      required this.lastUpdated,
      this.toDelete = false,
      this.isSynced = false});

  Routine.fromEntity({required Map<String, dynamic> entity})
      : id = entity["id"] as Id,
        name = entity["name"] as String,
        weight = entity["weight"] as int,
        expectedDuration = entity["expectedDuration"],
        realDuration = entity["realDuration"],
        customViewIndex = entity["customViewIndex"] as int,
        isSynced = true,
        toDelete = entity["toDelete"] as bool,
        lastUpdated =
            DateTime.tryParse(entity["lastUpdated"]) ?? Constants.today;

  Map<String, dynamic> toEntity() => {
        "id": id,
        "customViewIndex": customViewIndex,
        "name": name,
        "weight": weight,
        "expectedDuration": expectedDuration,
        "realDuration": realDuration,
        "toDelete": toDelete,
        "lastUpdated": lastUpdated.toIso8601String(),
      };

  @override
  Routine copy() => Routine(
      id: Constants.generateID(),
      name: name,
      weight: weight,
      expectedDuration: expectedDuration,
      realDuration: realDuration,
      lastUpdated: lastUpdated);

  @override
  Routine copyWith(
          {int? id,
          String? name,
          int? weight,
          int? expectedDuration,
          int? realDuration,
          List<Subtask>? routineTasks,
          DateTime? lastUpdated}) =>
      Routine(
          id: id ?? Constants.generateID(),
          name: name ?? this.name,
          weight: weight ?? this.weight,
          expectedDuration: expectedDuration ?? this.expectedDuration,
          realDuration: realDuration ?? this.realDuration,
          lastUpdated: lastUpdated ?? this.lastUpdated);

  @ignore
  @override
  List<Object?> get props => [
        id,
      ];

  @override
  String toString() => "Routine(id: $id,  customViewIndex: $customViewIndex, "
      "name: $name, weight: $weight, expectedDuration: $expectedDuration,"
      "routineTasks: $subtasks, isSynced: $isSynced, toDelete: $toDelete, lastUpdated: $lastUpdated)";
}
