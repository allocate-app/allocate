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
  @Index()
  Id id = Constants.generateID();

  @override
  @Index()
  String name;

  @Index()
  int weight;

  int expectedDuration;

  @Index()
  int realDuration;

  @ignore
  late List<Subtask> subtasks;

  @Index()
  int customViewIndex = -1;

  @Index()
  bool isSynced = false;

  @Index()
  bool toDelete = false;

  @override
  @Index()
  DateTime lastUpdated;

  Routine({
    required this.name,
    this.weight = 0,
    required this.expectedDuration,
    required this.realDuration,
    this.subtasks = const <Subtask>[],
    required this.lastUpdated,
  });

  Routine.fromEntity({required Map<String, dynamic> entity})
      : id = entity["id"] as Id,
        name = entity["name"] as String,
        weight = entity["weight"] as int,
        expectedDuration = entity["expectedDuration"],
        realDuration = entity["realDuration"],
        customViewIndex = entity["customViewIndex"] as int,
        isSynced = true,
        toDelete = false,
        subtasks = List.empty(growable: true),
        lastUpdated = DateTime.parse(entity["lastUpdated"]);

  Map<String, dynamic> toEntity() => {
        "id": id,
        "customViewIndex": customViewIndex,
        "name": name,
        "weight": weight,
        "expectedDuration": expectedDuration,
        "realDuration": realDuration,
        "lastUpdated": lastUpdated.toIso8601String(),
      };

  @override
  Routine copy() => Routine(
      name: name,
      weight: weight,
      expectedDuration: expectedDuration,
      realDuration: realDuration,
      subtasks: List.generate(subtasks.length, (i) => subtasks[i].copy()),
      lastUpdated: lastUpdated);

  @override
  Routine copyWith(
          {String? name,
          int? weight,
          int? expectedDuration,
          int? realDuration,
          List<Subtask>? routineTasks,
          DateTime? lastUpdated}) =>
      Routine(
          name: name ?? this.name,
          weight: weight ?? this.weight,
          expectedDuration: expectedDuration ?? this.expectedDuration,
          realDuration: realDuration ?? this.realDuration,
          subtasks: List.generate((routineTasks ?? subtasks).length,
              (i) => (routineTasks ?? subtasks)[i].copy()),
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
