import "package:equatable/equatable.dart";
import "package:isar/isar.dart";

import "../../util/constants.dart";
import "../../util/enums.dart";
import "../../util/interfaces/copyable.dart";
import "../../util/interfaces/i_repeatable.dart";
import "subtask.dart";

part "todo.g.dart";

@Collection(inheritance: false)
class ToDo with EquatableMixin implements Copyable<ToDo>, IRepeatable {
  @override
  @ignore
  ModelType modelType = ModelType.task;

  @override
  @ignore
  Fade fade = Fade.none;

  @override
  Id id;

  @Index()
  int? groupID;
  int groupIndex;
  int customViewIndex;

  @Enumerated(EnumType.ordinal)
  final TaskType taskType;

  @ignore
  late List<Subtask> subtasks;

  @override
  @Index()
  String name;
  String description;
  int weight;

  // Stored in seconds.
  int expectedDuration;
  int realDuration;
  @Enumerated(EnumType.ordinal)
  Priority priority;
  @Index()
  bool completed;
  @Index()
  @override
  DateTime? startDate;
  @Index()
  @override
  DateTime? originalStart;
  @override
  DateTime? originalDue;
  @Index()
  @override
  DateTime? dueDate;
  @Index()
  bool myDay;

  @override
  @Index()
  bool repeatable;

  @override
  @Index()
  int? repeatID;

  @Enumerated(EnumType.ordinal)
  @override
  Frequency frequency;
  @override
  @Index()
  @Enumerated(EnumType.ordinal)
  RepeatableState repeatableState;
  @override
  final List<bool> repeatDays;
  @override
  int repeatSkip;
  @override
  @Index()
  bool isSynced;
  @override
  @Index()
  bool toDelete;

  @override
  DateTime lastUpdated;

  ToDo(
      {required this.id,
      this.groupID,
      this.repeatID,
      this.groupIndex = -1,
      this.customViewIndex = -1,
      required this.taskType,
      required this.name,
      this.description = "",
      this.weight = 0,
      required this.expectedDuration,
      required this.realDuration,
      this.priority = Priority.low,
      this.startDate,
      this.dueDate,
      this.originalStart,
      this.originalDue,
      this.myDay = false,
      this.completed = false,
      this.repeatable = false,
      this.repeatableState = RepeatableState.normal,
      this.frequency = Frequency.once,
      required this.repeatDays,
      this.repeatSkip = 1,
      this.subtasks = const [],
      this.isSynced = false,
      this.toDelete = false,
      required this.lastUpdated});

  // -> From Entity.
  ToDo.fromEntity({required Map<String, dynamic> entity})
      : id = entity["id"] as int,
        groupID = entity["groupID"] as int?,
        repeatID = entity["repeatID"] as int,
        groupIndex = entity["groupIndex"] as int,
        customViewIndex = entity["customViewIndex"] as int,
        taskType = TaskType.values[entity["taskType"]],
        name = entity["name"] as String,
        description = entity["description"] as String,
        weight = entity["weight"] as int,
        expectedDuration = entity["expectedDuration"] as int,
        realDuration = entity["realDuration"] as int,
        priority = Priority.values[entity["priority"]],
        startDate = DateTime.tryParse(entity["startDate"] ?? ""),
        originalStart = DateTime.tryParse(entity["originalStart"] ?? ""),
        originalDue = DateTime.tryParse(entity["originalDue"] ?? ""),
        dueDate = DateTime.tryParse(entity["dueDate"] ?? ""),
        myDay = entity["myDay"] as bool,
        completed = entity["completed"] as bool,
        repeatable = entity["repeatable"] as bool,
        repeatableState = RepeatableState.values[entity["repeatableState"]],
        frequency = Frequency.values[entity["frequency"]],
        repeatDays = List.generate(7, (i) => entity["repeatDays"][i]),
        repeatSkip = entity["repeatSkip"] as int,
        isSynced = true,
        toDelete = entity["toDelete"] as bool,
        lastUpdated =
            DateTime.tryParse(entity["lastUpdated"] ?? "") ?? Constants.today;

  // No id for syncing - assigned via autoincrement online.
  Map<String, dynamic> toEntity() => {
        "id": id,
        "groupID": groupID,
        "repeatID": repeatID,
        "groupIndex": groupIndex,
        "customViewIndex": customViewIndex,
        "taskType": taskType.index,
        "name": name,
        "description": description,
        "weight": weight,
        "expectedDuration": expectedDuration,
        "realDuration": realDuration,
        "priority": priority.index,
        "startDate":
            (null != startDate) ? startDate?.toIso8601String() : startDate,
        "originalStart": (null != originalStart)
            ? originalStart!.toIso8601String()
            : originalStart,
        "originalDue": (null != originalDue)
            ? originalDue!.toIso8601String()
            : originalDue,
        "dueDate": (null != dueDate) ? dueDate?.toIso8601String() : dueDate,
        "myDay": myDay,
        "completed": completed,
        "repeatable": repeatable,
        "frequency": frequency.index,
        "repeatableState": repeatableState.index,
        "repeatDays": repeatDays,
        "repeatSkip": repeatSkip,
        "toDelete": toDelete,
        "lastUpdated": lastUpdated.toIso8601String(),
      };

  // TODO: Determine whether or not to copy id.
  @override
  ToDo copy() => ToDo(
        id: Constants.generateID(),
        groupID: groupID,
        repeatID: repeatID,
        taskType: taskType,
        groupIndex: groupIndex,
        customViewIndex: customViewIndex,
        name: name,
        description: description,
        weight: weight,
        expectedDuration: expectedDuration,
        realDuration: realDuration,
        priority: priority,
        startDate: startDate,
        dueDate: dueDate,
        originalStart: originalStart,
        originalDue: originalDue,
        myDay: myDay,
        completed: completed,
        repeatable: repeatable,
        frequency: frequency,
        repeatableState: repeatableState,
        repeatDays: List.generate(repeatDays.length, (i) => repeatDays[i]),
        // TODO: determine whether this makes sense.
        toDelete: false,
        isSynced: false,
        repeatSkip: repeatSkip,
        lastUpdated: lastUpdated,
      );

  @override
  ToDo copyWith({
    int? id,
    int? groupID,
    int? repeatID,
    int? groupIndex,
    int? customViewIndex,
    TaskType? taskType,
    String? name,
    String? description,
    int? weight,
    int? expectedDuration,
    int? realDuration,
    Priority? priority,
    DateTime? startDate,
    DateTime? dueDate,
    DateTime? originalStart,
    DateTime? originalDue,
    bool? myDay,
    bool? completed,
    bool? repeatable,
    Frequency? frequency,
    RepeatableState? repeatableState,
    List<bool>? repeatDays,
    int? repeatSkip,
    bool? isSynced,
    bool? toDelete,
    DateTime? lastUpdated,
  }) =>
      ToDo(
        id: id ?? Constants.generateID(),
        repeatID: repeatID ?? this.repeatID,
        groupID: groupID,
        groupIndex: groupIndex ?? this.groupIndex,
        customViewIndex: customViewIndex ?? this.customViewIndex,
        taskType: taskType ?? this.taskType,
        name: name ?? this.name,
        description: description ?? this.description,
        weight: weight ?? this.weight,
        expectedDuration: expectedDuration ?? this.expectedDuration,
        realDuration: realDuration ?? this.realDuration,
        priority: priority ?? this.priority,
        startDate: startDate ?? this.startDate,
        dueDate: dueDate ?? this.dueDate,
        originalStart: originalStart ?? this.originalStart,
        originalDue: originalDue ?? this.originalDue,
        myDay: myDay ?? this.myDay,
        // TODO: figure out whether this makes sense.
        isSynced: isSynced ?? false,
        toDelete: toDelete ?? false,
        completed: completed ?? this.completed,
        repeatable: repeatable ?? this.repeatable,
        frequency: frequency ?? this.frequency,
        repeatableState: repeatableState ?? this.repeatableState,
        repeatDays: (null != repeatDays)
            ? List.generate(repeatDays.length, (i) => repeatDays[i])
            : List.generate(this.repeatDays.length, (i) => this.repeatDays[i]),
        repeatSkip: repeatSkip ?? this.repeatSkip,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );

  @ignore
  @override
  List<Object?> get props => [
        id,
      ];

  @override
  String toString() =>
      "ToDo(id: $id, taskType: ${taskType.name} repeatID: $repeatID customViewIndex: $customViewIndex, groupID: $groupID, groupIndex: $groupIndex,"
      " name: $name, description: $description, weight: $weight, expectedDuration: $expectedDuration,"
      " priority: ${priority.name}, completed: $completed, startDate: $startDate, dueDate: $dueDate, originalStart: $originalStart, originalDue: $originalDue myDay: $myDay,"
      "repeatable: $repeatable, frequency: ${frequency.name}, repeatableState ${repeatableState.name}  repeatDays: $repeatDays,"
      "repeatSkip: $repeatSkip, isSynced: $isSynced, subtasks: $subtasks,"
      "toDelete: $toDelete), lastUpdated: $lastUpdated";
}
