import 'package:allocate/model/task/todo.dart';
import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';

import '../../util/enums.dart';
import '../../util/interfaces/copyable.dart';

/// DeadLines are meant for large-projects that have a due-date. They are just the project description
/// and that alone, so as to not overwhelm with the temptation of overloading subtasks.
/// Ideally, this is possibly something to store separately in the db.
/// On each day, grab the "warn me's": if it's today & 10mins (aprox) before, WARN!.
///
/// These should probably have priority.

@collection
class DeadLine with EquatableMixin implements Copyable<DeadLine> {
  @Name("id")
  Id id = Isar.autoIncrement;
  String description;
  DateTime startDate;
  DateTime dueDate;
  bool warnMe;
  @Enumerated(EnumType.ordinal)
  Priority priority;


  DeadLine({this.description = "", DateTime? startDate, DateTime? dueDate, this.warnMe = false, this.priority = Priority.low}):
      startDate = startDate ?? DateTime.now(),
      dueDate = dueDate ?? DateTime.now();

  DeadLine.fromEntity({required Map<String, dynamic> entity}) :
      id = entity["id"] as Id,
      description = entity["description"] as String,
      startDate = DateTime.parse(entity["startDate"]),
      dueDate = DateTime.parse(entity["dueDate"]),
      warnMe = entity["warnMe"] as bool,
      priority = Priority.values[entity["priority"]];

  Map<String, dynamic> toEntity() => {
    "id" : id,
    "description" : description,
    "startDate" : startDate.toIso8601String(),
    "dueDate" : dueDate.toIso8601String(),
    "warnMe" : warnMe,
    "priority" : priority.index
  };

  /// TODO: Add functionality to send a push notification to the user when approaching the deadline
  /// Maybe do an alert object. Or use firebase. Look this stuff up.
  /// MOVE TO A SERVICE.
  void setNotification()
  {
    // Get the cron package/localnotifications.
  }
  void cancelNotification()
  {
    // ibid.
  }

  @override
  List<Object?> get props => [startDate, dueDate, warnMe];

  @override
  DeadLine copy() => DeadLine(
    description: description,
    startDate: startDate,
    dueDate: dueDate,
    warnMe : warnMe,
    priority: priority,
  );

  @override
  DeadLine copyWith({
    String? description,
    DateTime? startDate,
    DateTime? dueDate,
    bool? warnMe,
    Priority? priority,
}) => DeadLine(
    description: description ?? this.description,
    startDate: startDate ?? this.startDate,
    dueDate: dueDate ?? this.dueDate,
    warnMe: warnMe ?? this.warnMe,
    priority: priority ?? this.priority
  );
}