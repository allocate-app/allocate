import "dart:convert";

import "package:equatable/equatable.dart";
import "package:isar/isar.dart";

import "../../util/interfaces/copyable.dart";
import "../../util/interfaces/i_model.dart";
import "subtask.dart";

part "routine.g.dart";

@Collection(inheritance: false)
class Routine with EquatableMixin implements Copyable<Routine>, IModel {
  Id id = Isar.autoIncrement;

  @override
  @Index()
  int? localID;

  @override
  @Index()
  String name;

  @Index()
  int weight;

  int expectedDuration;

  @Index()
  int realDuration;

  final List<SubTask> routineTasks;

  @Index()
  int customViewIndex = -1;

  @Index()
  bool isSynced = false;

  @Index()
  bool toDelete = false;

  @Index()
  DateTime lastUpdated;

  Routine(
      {required this.name,
      this.weight = 0,
      required this.expectedDuration,
      required this.realDuration,
      required this.routineTasks,
      required this.lastUpdated});

  Routine.fromEntity({required Map<String, dynamic> entity})
      : id = entity["id"] as Id,
        localID = entity["localID"] as int?,
        name = entity["name"] as String,
        weight = entity["weight"] as int,
        expectedDuration = entity["expectedDuration"],
        realDuration = entity["realDuration"],
        routineTasks = List.from(
            (jsonDecode(entity["routineTasks"]) as List)
                .map((rt) => SubTask.fromEntity(entity: rt)),
            growable: false),
        customViewIndex = entity["customViewIndex"] as int,
        isSynced = true,
        toDelete = false,
        lastUpdated = DateTime.parse(entity["lastUpdated"]);

  Map<String, dynamic> toEntity() => {
        "localID": localID,
        "customViewIndex": customViewIndex,
        "name": name,
        "weight": weight,
        "expectedDuration": expectedDuration,
        "realDuration": realDuration,
        "routineTasks": jsonEncode(
            routineTasks.map((rt) => rt.toEntity()).toList(growable: false)),
        "lastUpdated": lastUpdated.toIso8601String(),
      };

  @override
  Routine copy() => Routine(
      name: name,
      weight: weight,
      expectedDuration: expectedDuration,
      realDuration: realDuration,
      routineTasks: List.from(routineTasks),
      lastUpdated: lastUpdated);

  @override
  Routine copyWith(
          {String? name,
          int? weight,
          int? expectedDuration,
          int? realDuration,
          List<SubTask>? routineTasks,
          DateTime? lastUpdated}) =>
      Routine(
          name: name ?? this.name,
          weight: weight ?? this.weight,
          expectedDuration: expectedDuration ?? this.expectedDuration,
          realDuration: realDuration ?? this.realDuration,
          routineTasks: List.from(routineTasks ?? this.routineTasks),
          lastUpdated: lastUpdated ?? this.lastUpdated);

  @ignore
  @override
  List<Object?> get props => [
        //id,
        localID,
        name,
        weight,
        expectedDuration,
        routineTasks,
        customViewIndex,
        isSynced,
        toDelete,
      ];

  @override
  String toString() =>
      "Routine(id: $id, localID: $localID customViewIndex: $customViewIndex, "
      "name: $name, weight: $weight, expectedDuration: $expectedDuration,"
      "routineTasks: $routineTasks, isSynced: $isSynced, toDelete: $toDelete, lastUpdated: $lastUpdated)";
}
