import "dart:convert";

import "package:equatable/equatable.dart";
import "package:isar/isar.dart";

import "../../util/enums.dart";
import "../../util/interfaces/copyable.dart";
import "../../util/interfaces/i_model.dart";
import "subtask.dart";

part "todo.g.dart";

@Collection(inheritance: false)
class ToDo with EquatableMixin implements Copyable<ToDo>, IModel {
  @ignore
  @override
  int? localID;


  Id id = Isar.autoIncrement;

  @Index()
  int? groupID;
  @Index()
  int groupIndex;
  @Index()
  int customViewIndex;

  @Enumerated(EnumType.ordinal)
  final TaskType taskType;

  final List<SubTask> subTasks;

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
  DateTime startDate;
  @Index()
  DateTime dueDate;

  @Index()
  bool myDay;

  @Index()
  bool repeatable;

  @Index()
  int? repeatID;

  @Enumerated(EnumType.ordinal)
  Frequency frequency;
  final List<bool> repeatDays;
  int repeatSkip;
  @Index()
  bool isSynced = false;
  @Index()
  bool toDelete = false;
  @Index()
  DateTime lastUpdated;

  ToDo({this.groupID,
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
    required this.startDate,
    required this.dueDate,
    this.myDay = false,
    this.completed = false,
    this.repeatable = false,
    this.frequency = Frequency.once,
    required this.repeatDays,
    this.repeatSkip = 1,
    required this.subTasks,
    required this.lastUpdated});

  // -> From Entitiy.
  ToDo.fromEntity({required Map<String, dynamic> entity})
      : id = entity["id"] as Id,
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
        startDate = DateTime.parse(entity["startDate"]),
        dueDate = DateTime.parse(entity["dueDate"]),
        myDay = entity["myDay"] as bool,
        completed = entity["completed"] as bool,
        repeatable = entity["repeatable"] as bool,
        frequency = Frequency.values[entity["frequency"]],
        repeatDays = entity["repeatDays"] as List<bool>,
        repeatSkip = entity["repeatSkip"] as int,
        subTasks = List.from(
            (jsonDecode(entity["subTasks"]) as List)
                .map((st) => SubTask.fromEntity(entity: st)),
            growable: false),
        isSynced = true,
        toDelete = false,
        lastUpdated = DateTime.parse(entity["lastUpdated"]);

  // No id for syncing - assigned via autoincrement online.
  Map<String, dynamic> toEntity() =>
      {
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
        "startDate": startDate.toIso8601String(),
        "dueDate": dueDate.toIso8601String(),
        "myDay": myDay,
        "completed": completed,
        "repeatable": repeatable,
        "frequency": frequency.index,
        "repeatDays": repeatDays,
        "repeatSkip": repeatSkip,
        "subTasks": jsonEncode(
            subTasks.map((st) => st.toEntity()).toList(growable: false)),
        "lastUpdated": lastUpdated.toIso8601String()
      };

  @override
  ToDo copy() =>
      ToDo(
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
          subTasks: List.from(subTasks),
          lastUpdated: lastUpdated);

  @override
  ToDo copyWith({int? groupID,
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
    List<SubTask>? subTasks,
    DateTime? lastUpdated}) =>
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
          subTasks: List.from(
            subTasks ?? this.subTasks,
          ),
          lastUpdated: lastUpdated ?? this.lastUpdated);

  @ignore
  @override
  List<Object?> get props =>
      [
        // Consider bringing this back once full app is built.
        // Right now, there is a race-condition in testing due to db id.
        // id,
        repeatID,
        customViewIndex,
        groupID,
        groupIndex,
        name,
        description,
        weight,
        expectedDuration,
        priority,
        completed,
        startDate,
        dueDate,
        myDay,
        repeatable,
        frequency,
        repeatDays,
        repeatSkip,
        isSynced,
        subTasks,
        toDelete,
      ];

  @override
  String toString() =>
      "ToDo(id: $id, taskType: ${taskType
          .name} repeatID: $repeatID customViewIndex: $customViewIndex, groupID: $groupID, groupIndex: $groupIndex,"
          " name: $name, description: $description, weight: $weight, expectedDuration: $expectedDuration,"
          " priority: ${priority
          .name}, completed: $completed, startDate: $startDate, dueDate: $dueDate, myDay: $myDay,"
          "repeatable: $repeatable, frequency: ${frequency
          .name},  repeatDays: $repeatDays,"
          "repeatSkip: $repeatSkip, isSynced: $isSynced, subTasks: $subTasks,"
          "toDelete: $toDelete), lastUpdated: $lastUpdated";
}
