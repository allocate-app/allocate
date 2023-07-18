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

part "deadline.g.dart";

@Collection(inheritance: false)
class Deadline with EquatableMixin implements Copyable<Deadline> {
  Id id = Isar.autoIncrement;
  @Index()
  int customViewIndex = -1;
  @Index()
  String name;
  String description;
  DateTime startDate;
  @Index()
  DateTime dueDate;
  DateTime warnDate;
  bool warnMe;
  @Enumerated(EnumType.ordinal)
  Priority priority;
  @Index()
  bool isSynced = false;
  @Index()
  bool toDelete = false;

  Deadline(
      {required this.name,
      this.description = "",
      required this.startDate,
      required this.dueDate,
      required this.warnDate,
      this.warnMe = false,
      this.priority = Priority.low});

  Deadline.fromEntity({required Map<String, dynamic> entity})
      : id = entity["id"] as Id,
        customViewIndex = entity["customViewPosition"] as int,
        name = entity["name"] as String,
        description = entity["description"] as String,
        startDate = DateTime.parse(entity["startDate"]),
        dueDate = DateTime.parse(entity["dueDate"]),
        warnDate = DateTime.parse(entity["warnDate"]),
        warnMe = entity["warnMe"] as bool,
        priority = Priority.values[entity["priority"]],
        isSynced = true,
        toDelete = false;

  Map<String, dynamic> toEntity() => {
        "id": id,
        "customViewPosition": customViewIndex,
        "name": name,
        "description": description,
        "startDate": startDate.toIso8601String(),
        "dueDate": dueDate.toIso8601String(),
        "warnDate": warnDate.toIso8601String(),
        "warnMe": warnMe,
        "priority": priority.index
      };

  @override
  Deadline copy() => Deadline(
        name: name,
        description: description,
        startDate: startDate,
        dueDate: dueDate,
        warnDate: warnDate,
        warnMe: warnMe,
        priority: priority,
      );

  @override
  Deadline copyWith({
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? dueDate,
    DateTime? warnDate,
    bool? warnMe,
    Priority? priority,
  }) =>
      Deadline(
          name: name ?? this.name,
          description: description ?? this.description,
          startDate: startDate ?? this.startDate,
          dueDate: dueDate ?? this.dueDate,
          warnDate: warnDate ?? this.warnDate,
          warnMe: warnMe ?? this.warnMe,
          priority: priority ?? this.priority);

  @ignore
  @override
  List<Object?> get props => [startDate, dueDate, warnDate, warnMe];
}
