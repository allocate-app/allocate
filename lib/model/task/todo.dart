import "dart:convert";

import "package:equatable/equatable.dart";
import "package:isar/isar.dart";

import "../../util/enums.dart";
import "../../util/interfaces/copyable.dart";
import "subtask.dart";

part "todo.g.dart";

@Collection(inheritance: false)
class ToDo with EquatableMixin implements Copyable<ToDo> {
  Id id = Isar.autoIncrement;

  @Index()
  int? groupID;
  @Index()
  int groupIndex = -1;
  @Index()
  int customViewIndex = -1;

  @Enumerated(EnumType.ordinal)
  final TaskType taskType;

  final List<SubTask> subTasks;

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
  DateTime dueDate;

  @Index()
  bool myDay;

  @Index()
  bool repeatable;

  @Index()
  int? repeatID;

  @Enumerated(EnumType.ordinal)
  Frequency frequency;
  @Enumerated(EnumType.ordinal)
  CustomFrequency customFreq;
  List<bool> repeatDays;
  int repeatSkip;
  @Index()
  bool isSynced = false;
  @Index()
  bool toDelete = false;

  ToDo({
    this.groupID,
    this.repeatID,
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
    this.customFreq = CustomFrequency.weekly,
    required this.repeatDays,
    this.repeatSkip = 1,
    required this.subTasks,
  });

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
        customFreq = CustomFrequency.values[entity["customFreq"]],
        repeatDays = entity["repeatDays"] as List<bool>,
        repeatSkip = entity["repeatSkip"] as int,
        subTasks = (jsonDecode(entity["subTasks"])["subTasks"]! as List)
            .map((st) => SubTask.fromEntity(entity: st))
            .toList(growable: true),
        isSynced = entity["isSynced"] as bool,
        toDelete = entity["toDelete"] as bool;

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
        "startDate": startDate.toIso8601String(),
        "dueDate": dueDate.toIso8601String(),
        "myDay": myDay,
        "completed": completed,
        "repeatable": repeatable,
        "frequency": frequency.index,
        "customFreq": customFreq.index,
        "repeatDays": repeatDays,
        "repeatSkip": repeatSkip,
        "subTasks": jsonEncode(subTasks.map((st) => st.toEntity())),
        "isSynced": isSynced,
        "toDelete": toDelete
      };

  @override
  ToDo copy() => ToDo(
      groupID: groupID,
      repeatID: repeatID,
      taskType: taskType,
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
      customFreq: customFreq,
      repeatDays: List.from(repeatDays),
      repeatSkip: repeatSkip,
      subTasks: List.from(subTasks));

  @override
  ToDo copyWith({
    int? groupID,
    int? repeatID,
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
    CustomFrequency? customFreq,
    List<bool>? repeatDays,
    int? repeatSkip,
    List<SubTask>? subTasks,
  }) =>
      ToDo(
          repeatID: repeatID ?? this.repeatID,
          groupID: groupID,
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
          customFreq: customFreq ?? this.customFreq,
          repeatDays: List.from(repeatDays ?? this.repeatDays),
          repeatSkip: repeatSkip ?? this.repeatSkip,
          subTasks: List.from(subTasks ?? this.subTasks));
  @ignore
  @override
  List<Object?> get props => [
        id,
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
        customFreq,
        repeatDays,
        repeatSkip,
        isSynced,
        subTasks,
        toDelete
      ];

  @override
  toString() =>
      "ToDo(id: $id, repeatID: $repeatID customViewIndex: $customViewIndex, groupID: $groupID, groupIndex: $groupIndex,"
      " name: $name, description: $description, weight: $weight, expectedDuration: $expectedDuration,"
      " priority: $priority, completed: $completed, startDate: $startDate, dueDate: $dueDate, myDay: $myDay,"
      "repeatable: $repeatable, frequency: $frequency, customFreq: $customFreq, repeatDays: $repeatDays,"
      "repeatSkip: $repeatSkip, isSynced: $isSynced, subTasks: $subTasks,"
      "toDelete: $toDelete)";
}
