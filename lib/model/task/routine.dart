import "dart:convert";
import "package:allocate/model/task/subtask.dart";
import "package:isar/isar.dart";
import "../../util/enums.dart";
import "../../util/interfaces/copyable.dart";

// TODO: Does not need to be repeatable. Repeats are implicit > store a link in the user class.
// TODO: Implement a provider class (UI).
@collection
class Routine implements Copyable<Routine> {
  static const int maxTasksPerRoutine = 10;
  Id id = Isar.autoIncrement;

  @Enumerated(EnumType.ordinal)
  RoutineTime routineTime;

  String name;
  int weight;
  int expectedDuration;
  final List<SubTask> routineTasks;
  bool isSynced;
  bool toDelete;

  Routine(
      {required this.routineTime,
      required this.name,
      this.weight = 0,
      Duration expectedDuration = const Duration(hours: 1),
      List<SubTask>? routineTasks,
      this.isSynced = true,
      this.toDelete = false})
      : expectedDuration = expectedDuration.inSeconds,
        routineTasks = routineTasks ?? List.empty(growable: true);

  Routine.fromEntity({required Map<String, dynamic> entity})
      : id = entity["id"] as Id,
        routineTime = RoutineTime.values[entity["routineTime"]],
        name = entity["name"] as String,
        weight = entity["weight"] as int,
        expectedDuration = entity["expectedDuration"],
        routineTasks =
            (jsonDecode(entity["routineTasks"])["routineTasks"] as List)
                .map((rt) => SubTask.fromEntity(entity: rt))
                .toList(),
        isSynced = entity["isSynced"],
        toDelete = entity["toDelete"];

  Map<String, dynamic> toEntity() => {
        "id": id,
        "routineTime": routineTime.index,
        "name": name,
        "weight": weight,
        "expectedDuration": expectedDuration,
        "routineTasks": jsonEncode(routineTasks.map((rt) => rt.toEntity())),
        "isSynced": isSynced,
        "toDelete": toDelete
      };

  @override
  Routine copy() => Routine(
      name: name,
      routineTime: routineTime,
      weight: weight,
      expectedDuration: Duration(seconds: expectedDuration),
      routineTasks: List.from(routineTasks));

  @override
  Routine copyWith({
    String? name,
    RoutineTime? routineTime,
    int? weight,
    Duration? expectedDuration,
    List<SubTask>? routineTasks,
  }) =>
      Routine(
          name: name ?? this.name,
          routineTime: routineTime ?? this.routineTime,
          weight: weight ?? this.weight,
          expectedDuration:
              expectedDuration ?? Duration(seconds: this.expectedDuration),
          routineTasks: (null != routineTasks)
              ? List.from(routineTasks)
              : List.from(this.routineTasks));

  //TODO: implement.

  @override
  List<Object> get props => [
        id,
        routineTime,
        name,
        weight,
        expectedDuration,
        routineTasks,
        isSynced,
        toDelete
      ];
}
