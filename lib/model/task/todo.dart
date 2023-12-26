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
  ModelType get repeatableType => modelType;

  @override
  @ignore
  Fade fade = Fade.none;

  @override
  Id id = Constants.generateID();

  @Index()
  int? groupID;
  @Index()
  int groupIndex;
  @Index()
  int customViewIndex;

  @Enumerated(EnumType.ordinal)
  final TaskType taskType;

  @ignore
  late List<Subtask> subtasks;

  @override
  @Index()
  String name;
  String description;
  @Index()
  int weight;

  // Stored in seconds.
  int expectedDuration;
  @Index()
  int realDuration;
  @Enumerated(EnumType.ordinal)
  Priority priority;
  @Index()
  bool completed;
  @override
  DateTime? startDate;
  @Index()
  @override
  DateTime? dueDate;
  @Index()
  bool myDay;

  @Index()
  bool repeatable;

  @Index()
  int? repeatID;

  @Enumerated(EnumType.ordinal)
  @override
  Frequency frequency;
  final List<bool> repeatDays;
  int repeatSkip;
  @Index()
  bool isSynced = false;
  @Index()
  bool toDelete = false;

  @override
  @Index()
  DateTime lastUpdated;

  ToDo(
      {this.groupID,
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
      this.myDay = false,
      this.completed = false,
      this.repeatable = false,
      this.frequency = Frequency.once,
      required this.repeatDays,
      this.repeatSkip = 1,
      this.subtasks = const [],
      required this.lastUpdated}) {
    // Constants.intMax is reserved, generate until the id is different.
    while (Constants.intMax == id) {
      id = Constants.generateID();
    }
  }

  // -> From Entitiy.
  ToDo.fromEntity({required Map<String, dynamic> entity})
      : id = entity["id"] as int,
        groupID = entity["groupID"] as int,
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
        startDate = DateTime.tryParse(entity["startDate"]),
        dueDate = DateTime.tryParse(entity["dueDate"]),
        myDay = entity["myDay"] as bool,
        completed = entity["completed"] as bool,
        repeatable = entity["repeatable"] as bool,
        frequency = Frequency.values[entity["frequency"]],
        repeatDays = entity["repeatDays"] as List<bool>,
        repeatSkip = entity["repeatSkip"] as int,
        isSynced = true,
        toDelete = false,
        lastUpdated = DateTime.parse(entity["lastUpdated"]);

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
        "dueDate": (null != dueDate) ? dueDate?.toIso8601String() : dueDate,
        "myDay": myDay,
        "completed": completed,
        "repeatable": repeatable,
        "frequency": frequency.index,
        "repeatDays": repeatDays,
        "repeatSkip": repeatSkip,
        "lastUpdated": lastUpdated.toIso8601String(),
      };

  @override
  ToDo copy() => ToDo(
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
        myDay: myDay,
        completed: completed,
        repeatable: repeatable,
        frequency: frequency,
        repeatDays: List.from(repeatDays),
        repeatSkip: repeatSkip,
        lastUpdated: lastUpdated,
      );

  @override
  ToDo copyWith({
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
    bool? myDay,
    bool? completed,
    bool? repeatable,
    Frequency? frequency,
    List<bool>? repeatDays,
    int? repeatSkip,
    DateTime? lastUpdated,
  }) =>
      ToDo(
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
        myDay: myDay ?? this.myDay,
        completed: completed ?? this.completed,
        repeatable: repeatable ?? this.repeatable,
        frequency: frequency ?? this.frequency,
        repeatDays: List.from(repeatDays ?? this.repeatDays),
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
      " priority: ${priority.name}, completed: $completed, startDate: $startDate, dueDate: $dueDate, myDay: $myDay,"
      "repeatable: $repeatable, frequency: ${frequency.name},  repeatDays: $repeatDays,"
      "repeatSkip: $repeatSkip, isSynced: $isSynced, subtasks: $subtasks,"
      "toDelete: $toDelete), lastUpdated: $lastUpdated";
}
