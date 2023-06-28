import "dart:convert";
import "package:allocate/model/task/subtask.dart";
import "package:equatable/equatable.dart";
import "package:isar/isar.dart";
import "../../util/enums.dart";
import "../../util/interfaces/copyable.dart";
import "group.dart";

part "todo.g.dart";

// TODO: Implement a provider class (UI).
final Map <TaskType, int> numTasks = {
  TaskType.small : 0,
  TaskType.large : 5,
  TaskType.huge : double.maxFinite.toInt()
};

class ToDo with EquatableMixin implements Copyable<ToDo> {
  // To set the id in todoservice once db is handled.
  // SOMETHING akin to this:
  // FirebaseFirestore.instance.collection("tablename").doc().id;
  Id id = Isar.autoIncrement;

  final group = IsarLink<Group>();
  int? groupPosition;

  @Enumerated(EnumType.ordinal)
  final TaskType taskType;
  final int maxSubTasks;
  final List<SubTask> subTasks;

  String name;
  String description;
  int weight;
  // Stored in seconds.
  int expectedDuration;
  @Enumerated(EnumType.ordinal)
  Priority priority;
  bool completed = false;
  DateTime dueDate;

  bool myDay;
  int? myDayPosition;

  // TODO: repeat stuff. Handle in repository api.
  bool repeatable;
  Frequency frequency;
  List<bool> repeatDays;
  int repeatSkip;
  bool isSynced;
  bool toDelete;

  ToDo(
      {required this.taskType,
      required this.name,
      this.description = "",
      this.weight = 0,
      Duration expectedDuration = Duration.zero,
      this.priority = Priority.low,
      DateTime? dueDate,
      this.myDay = false,
      this.repeatable = false,
      this.frequency = Frequency.once,
      List<bool>? repeatDays,
      this.repeatSkip = 1,
      this.isSynced = true,
      this.toDelete = false,
      List<SubTask>? subTasks,})
      : maxSubTasks = numTasks[taskType]!,
        expectedDuration = expectedDuration.inSeconds,
        repeatDays = repeatDays ?? List.filled(7, false, growable: false),
        dueDate = dueDate ?? DateTime.now(),
        subTasks = subTasks ?? List.empty(growable: true);

  // -> From Entitiy.
  ToDo.fromEntity({required Map<String, dynamic> entity})
      : id = entity["id"] as Id,
        groupPosition = entity["groupPosition"] as int?,
        taskType = TaskType.values[entity["taskType"]],
        maxSubTasks = entity["maxSubTasks"] as int,
        name = entity["name"] as String,
        description = entity["description"] as String,
        weight = entity["weight"] as int,
        expectedDuration = entity["expectedDuration"] as int,
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
        toDelete = entity["toDelete"] as bool {
    Group? g = (null != jsonDecode(entity["group"]))
        ? Group.fromEntity(entity: entity["group"])
        : null;
    group.value = g;
  }

  Map<String, dynamic> toEntity() => {
        "id": id,
        "groupPostion": groupPosition,
        "taskType": taskType.index,
        "maxSubTasks": maxSubTasks,
        "name": name,
        "description": description,
        "weight": weight,
        "expectedDuration": expectedDuration,
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
        "toDelete": toDelete,
        "group": (null != group.value) ? group.value!.toEntity() : null
      };

  @override
  ToDo copy() => ToDo(
      taskType: taskType,
      name: name,
      description: description,
      weight: weight,
      expectedDuration: Duration(seconds: expectedDuration),
      priority: priority,
      dueDate: dueDate,
      myDay: false,
      repeatable: repeatable,
      frequency: frequency,
      repeatDays: List.from(repeatDays),
      repeatSkip: repeatSkip,
      isSynced: isSynced,
      toDelete: toDelete,
      subTasks: List.from(subTasks));

  @override
  ToDo copyWith({
    TaskType? taskType,
    String? name,
    String? description,
    int? weight,
    Duration? expectedDuration,
    Priority? priority,
    DateTime? dueDate,
    bool? myDay,
    bool? repeatable,
    Frequency? frequency,
    List<bool>? repeatDays,
    int? repeatSkip,
    bool? isSynced,
    bool? toDelete,
    List<SubTask>? subTasks,
}) => ToDo(
    taskType: taskType ?? this.taskType,
    name: name ?? this.name,
    description: description ?? this.description,
    weight: weight ?? this.weight,
    expectedDuration: expectedDuration ?? Duration(seconds: this.expectedDuration),
    priority: priority ?? this.priority,
    dueDate: dueDate ?? this.dueDate,
    myDay: myDay ?? false,
    repeatable: repeatable ?? this.repeatable,
    repeatDays: (null != repeatDays) ? List.from(repeatDays) : List.from(this.repeatDays),
    repeatSkip: repeatSkip ?? this.repeatSkip,
    isSynced: isSynced ?? this.isSynced,
    toDelete: toDelete ?? this.toDelete,
    subTasks: (null != subTasks && subTasks.length <= numTasks[taskType ?? this.taskType]!) ? List.from(subTasks) :
    (this.subTasks.length <= numTasks[taskType ?? this.taskType]!) ? List.from(this.subTasks) : null
  );

  @override
  List<Object> get props => [
        id,
        group.value.toString(),
        groupPosition.toString(),
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
        isSynced
      ];
}
