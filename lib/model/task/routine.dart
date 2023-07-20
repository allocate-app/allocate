import "dart:convert";

import "package:allocate/model/task/subtask.dart";
import "package:isar/isar.dart";

import "../../util/enums.dart";
import "../../util/interfaces/copyable.dart";

part "routine.g.dart";

// Future TODO: subtask sorting

@Collection(inheritance: false)
class Routine implements Copyable<Routine> {
  Id id = Isar.autoIncrement;

  @Enumerated(EnumType.ordinal)
  RoutineTime routineTime;

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

  Routine(
      {required this.routineTime,
      required this.name,
      this.weight = 0,
      required this.expectedDuration,
      required this.realDuration,
      required this.routineTasks});

  Routine.fromEntity({required Map<String, dynamic> entity})
      : id = entity["id"] as Id,
        routineTime = RoutineTime.values[entity["routineTime"]],
        name = entity["name"] as String,
        weight = entity["weight"] as int,
        expectedDuration = entity["expectedDuration"],
        realDuration = entity["realDuration"],
        routineTasks =
            (jsonDecode(entity["routineTasks"])["routineTasks"] as List)
                .map((rt) => SubTask.fromEntity(entity: rt))
                .toList(),
        customViewIndex = entity["customViewIndex"] as int,
        isSynced = true,
        toDelete = false;

  Map<String, dynamic> toEntity() => {
        "id": id,
        "routineTime": routineTime.index,
        "name": name,
        "weight": weight,
        "expectedDuration": expectedDuration,
        "realDuration": realDuration,
        "routineTasks": jsonEncode(routineTasks.map((rt) => rt.toEntity())),
        "customViewIndex": customViewIndex
      };

  @override
  Routine copy() => Routine(
      name: name,
      routineTime: routineTime,
      weight: weight,
      expectedDuration: expectedDuration,
      realDuration: realDuration,
      routineTasks: List.from(routineTasks));

  @override
  Routine copyWith({
    String? name,
    RoutineTime? routineTime,
    int? weight,
    int? expectedDuration,
    int? realDuration,
    List<SubTask>? routineTasks,
  }) =>
      Routine(
          name: name ?? this.name,
          routineTime: routineTime ?? this.routineTime,
          weight: weight ?? this.weight,
          expectedDuration: expectedDuration ?? this.expectedDuration,
          realDuration: realDuration ?? this.realDuration,
          routineTasks: List.from(routineTasks ?? this.routineTasks));

  @ignore
  @override
  List<Object> get props => [
        id,
        routineTime,
        name,
        weight,
        expectedDuration,
        routineTasks,
        customViewIndex,
        isSynced,
        toDelete
      ];
}
