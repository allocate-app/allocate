import "dart:convert";

import "package:allocate/model/task/subtask.dart";
import "package:equatable/equatable.dart";
import "package:isar/isar.dart";

import "../../util/enums.dart";
import "../../util/interfaces/copyable.dart";
import "../../util/numbers.dart";

part "todo.g.dart";

// TODO: Implement a provider class (UI).

// TODO: implement a subtask sorting object with serialization.
class ToDo with EquatableMixin implements Copyable<ToDo> {
  static Map<TaskType, int> numTasks = {
    TaskType.small: 0,
    TaskType.large: 5,
    TaskType.huge: double.maxFinite.toInt()
  };
  static const int lowerBound = 1;
  static const int upperBound = 10;

  Id id = Isar.autoIncrement;

  int groupID = -1;
  int groupIndex = -1;
  int customViewIndex = -1;

  @Enumerated(EnumType.ordinal)
  final TaskType taskType;
  final int maxSubTasks;
  final List<SubTask> subTasks;

  String name;
  String description;
  int weight;
  // Stored in seconds.
  int expectedDuration;
  int realDuration;

  @Enumerated(EnumType.ordinal)
  Priority priority;
  bool completed = false;
  DateTime dueDate;

  bool myDay;
  int? myDayPosition;

  bool repeatable;
  Frequency frequency;
  List<bool> repeatDays;
  int repeatSkip;
  bool isSynced = false;
  bool toDelete = false;

  ToDo({
    required this.taskType,
    required this.name,
    this.description = "",
    this.weight = 0,
    Duration expectedDuration = Duration.zero,
    int? realDuration,
    this.priority = Priority.low,
    DateTime? dueDate,
    this.repeatable = false,
    this.frequency = Frequency.once,
    List<bool>? repeatDays,
    this.repeatSkip = 1,
    List<SubTask>? subTasks,
  })  : maxSubTasks = numTasks[taskType]!,
        expectedDuration = expectedDuration.inSeconds,
        realDuration = realDuration ??
            (smoothstep(x: weight, v0: lowerBound, v1: upperBound) *
                expectedDuration.inSeconds) as int,
        repeatDays = repeatDays ?? List.filled(7, false, growable: false),
        dueDate = dueDate ?? DateTime.now(),
        subTasks = subTasks ?? List.empty(growable: true);

  fromSubTask({required SubTask subTask}) => ToDo(
      taskType: TaskType.small, name: subTask.name, weight: subTask.weight);

  // -> From Entitiy.
  ToDo.fromEntity({required Map<String, dynamic> entity})
      : id = entity["id"] as Id,
        groupID = entity["groupID"] as int,
        groupIndex = entity["groupIndex"] as int,
        taskType = TaskType.values[entity["taskType"]],
        maxSubTasks = entity["maxSubTasks"] as int,
        name = entity["name"] as String,
        description = entity["description"] as String,
        weight = entity["weight"] as int,
        expectedDuration = entity["expectedDuration"] as int,
        realDuration = entity["realDuration"] as int,
        priority = Priority.values[entity["priority"]],
        dueDate = DateTime.parse(entity["dueDate"]),
        myDay = entity["myDay"] as bool,
        myDayPosition = entity["myDayPosition"] as int?,
        repeatable = entity["repeatable"] as bool,
        frequency = Frequency.values[entity["frequency"]],
        repeatDays = entity["repeatDays"],
        repeatSkip = entity["repeatSkip"] as int,
        subTasks = (jsonDecode(entity["subTasks"])["subTasks"]! as List)
            .map((st) => SubTask.fromEntity(entity: st))
            .toList(),
        isSynced = entity["isSynced"] as bool,
        toDelete = entity["toDelete"] as bool;

  Map<String, dynamic> toEntity() => {
        "id": id,
        "groupID": groupID,
        "groupIndex": groupIndex,
        "taskType": taskType.index,
        "maxSubTasks": maxSubTasks,
        "name": name,
        "description": description,
        "weight": weight,
        "expectedDuration": expectedDuration,
        "realDuration": realDuration,
        "priority": priority.index,
        "dueDate": dueDate.toIso8601String(),
        "myDay": myDay,
        "myDayPosition": myDayPosition,
        "repeatable": repeatable,
        "frequency": frequency.index,
        "repeatDays": repeatDays,
        "repeatSkip": repeatSkip,
        "subTasks": jsonEncode(subTasks.map((st) => st.toEntity())),
        "isSynced": isSynced,
        "toDelete": toDelete
      };

  @override
  ToDo copy() => ToDo(
      taskType: taskType,
      name: name,
      description: description,
      weight: weight,
      expectedDuration: Duration(seconds: expectedDuration),
      realDuration: realDuration,
      priority: priority,
      dueDate: dueDate,
      repeatable: repeatable,
      frequency: frequency,
      repeatDays: List.from(repeatDays),
      repeatSkip: repeatSkip,
      subTasks: List.from(subTasks));

  //TODO: remove myDay.
  @override
  ToDo copyWith({
    TaskType? taskType,
    String? name,
    String? description,
    int? weight,
    Duration? expectedDuration,
    Priority? priority,
    DateTime? dueDate,
    bool? repeatable,
    Frequency? frequency,
    List<bool>? repeatDays,
    int? repeatSkip,
    bool? isSynced,
    bool? toDelete,
    List<SubTask>? subTasks,
  }) =>
      ToDo(
          taskType: taskType ?? this.taskType,
          name: name ?? this.name,
          description: description ?? this.description,
          weight: weight ?? this.weight,
          expectedDuration:
              expectedDuration ?? Duration(seconds: this.expectedDuration),
          priority: priority ?? this.priority,
          dueDate: dueDate ?? this.dueDate,
          repeatable: repeatable ?? this.repeatable,
          repeatDays: (null != repeatDays)
              ? List.from(repeatDays)
              : List.from(this.repeatDays),
          repeatSkip: repeatSkip ?? this.repeatSkip,
          subTasks: (null != subTasks &&
                  subTasks.length <= numTasks[taskType ?? this.taskType]!)
              ? List.from(subTasks)
              : (this.subTasks.length <= numTasks[taskType ?? this.taskType]!)
                  ? List.from(this.subTasks)
                  : null);

  @override
  List<Object> get props => [
        id,
        customViewIndex,
        groupID,
        groupIndex,
        maxSubTasks,
        name,
        description,
        weight,
        expectedDuration,
        priority,
        completed,
        dueDate,
        myDay,
        repeatable,
        frequency,
        repeatDays,
        repeatSkip,
        isSynced,
        toDelete
      ];
}
