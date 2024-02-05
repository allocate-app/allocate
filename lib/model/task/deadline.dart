import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';

import '../../util/constants.dart';
import '../../util/enums.dart';
import '../../util/interfaces/copyable.dart';
import '../../util/interfaces/i_repeatable.dart';

/// DeadLines are meant for large-projects that have a due-date. They are just the project description
/// and that alone, so as to not overwhelm with the temptation of overloading subtasks.

part "deadline.g.dart";

@Collection(inheritance: false)
class Deadline with EquatableMixin implements Copyable<Deadline>, IRepeatable {
  @override
  @ignore
  ModelType modelType = ModelType.deadline;

  @override
  @ignore
  Fade fade = Fade.none;

  @override
  @Index()
  late Id id;
  @Index()
  int customViewIndex;
  @override
  @Index()
  int? repeatID;
  @Index()
  int? notificationID;
  @override
  @Index()
  String name;
  String description;

  @override
  @Index()
  DateTime? startDate;
  @override
  @Index()
  DateTime? originalStart;
  @Index()
  @override
  DateTime? dueDate;
  @override
  DateTime? originalDue;
  DateTime? warnDate;
  DateTime? originalWarn;
  @Index()
  bool warnMe;

  @Enumerated(EnumType.ordinal)
  Priority priority;

  @override
  @Index()
  bool repeatable;
  @override
  @Enumerated(EnumType.ordinal)
  Frequency frequency;
  @Index()
  @override
  @Enumerated(EnumType.ordinal)
  RepeatableState repeatableState;
  @override
  List<bool> repeatDays;
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

  Deadline(
      {required this.id,
      this.repeatID,
      this.notificationID,
      this.customViewIndex = -1,
      required this.name,
      this.description = "",
      this.startDate,
      this.dueDate,
      this.originalStart,
      this.originalDue,
      this.originalWarn,
      this.warnDate,
      this.warnMe = false,
      this.priority = Priority.low,
      this.repeatable = false,
      this.repeatableState = RepeatableState.normal,
      this.frequency = Frequency.once,
      required this.repeatDays,
      this.repeatSkip = 1,
      this.isSynced = false,
      this.toDelete = false,
      required this.lastUpdated});

  Deadline.fromEntity({required Map<String, dynamic> entity})
      : id = entity["id"] as Id,
        customViewIndex = entity["customViewIndex"] as int,
        repeatID = entity["repeatID"] as int?,
        notificationID = entity["notificationID"] as int?,
        name = entity["name"] as String,
        description = entity["description"] as String,
        startDate = DateTime.tryParse(entity["startDate"] ?? ""),
        originalStart = DateTime.tryParse(entity["originalStart"] ?? ""),
        originalDue = DateTime.tryParse(entity["originalDue"] ?? ""),
        dueDate = DateTime.tryParse(entity["dueDate"] ?? ""),
        originalWarn = DateTime.tryParse(entity["originalWarn"] ?? ""),
        warnDate = DateTime.tryParse(entity["warnDate"] ?? ""),
        warnMe = entity["warnMe"] as bool,
        priority = Priority.values[entity["priority"]],
        repeatableState = RepeatableState.values[entity["repeatableState"]],
        repeatable = entity["repeatable"] as bool,
        frequency = Frequency.values[entity["frequency"]],
        repeatDays = List.generate(7, (i) => entity["repeatDays"][i]),
        repeatSkip = entity["repeatSkip"] as int,
        lastUpdated =
            DateTime.tryParse(entity["lastUpdated"] ?? "") ?? Constants.today,
        toDelete = entity["toDelete"] as bool,
        isSynced = true;

  // No id for syncing - assigned via autoincrement online.
  Map<String, dynamic> toEntity() => {
        "id": id,
        "customViewIndex": customViewIndex,
        "notificationID": notificationID,
        "repeatID": repeatID,
        "name": name,
        "description": description,
        "startDate":
            (null != startDate) ? startDate?.toIso8601String() : startDate,
        "originalStart": (null != originalStart)
            ? originalStart!.toIso8601String()
            : originalStart,
        "originalDue": (null != originalDue)
            ? originalDue!.toIso8601String()
            : originalDue,
        "originalWarn": (null != originalWarn)
            ? originalWarn!.toIso8601String()
            : originalWarn,
        "dueDate": (null != dueDate) ? dueDate?.toIso8601String() : dueDate,
        "warnDate": (null != warnDate) ? warnDate?.toIso8601String() : warnDate,
        "warnMe": warnMe,
        "priority": priority.index,
        "repeatable": repeatable,
        "repeatableState": repeatableState.index,
        "frequency": frequency.index,
        "repeatDays": repeatDays,
        "repeatSkip": repeatSkip,
        "toDelete": toDelete,
        "lastUpdated": lastUpdated.toIso8601String()
      };

  @override
  Deadline copy() => Deadline(
        id: Constants.generateID(),
        notificationID: notificationID,
        repeatID: repeatID,
        customViewIndex: customViewIndex,
        name: name,
        description: description,
        startDate: startDate,
        dueDate: dueDate,
        warnDate: warnDate,
        originalStart: originalStart,
        originalDue: originalDue,
        originalWarn: originalWarn,
        warnMe: warnMe,
        priority: priority,
        repeatable: repeatable,
        frequency: frequency,
        repeatDays: List.generate(repeatDays.length, (i) => repeatDays[i]),
        repeatableState: repeatableState,
        repeatSkip: repeatSkip,
        lastUpdated: lastUpdated,
      );

  @override
  Deadline copyWith(
          {int? id,
          int? repeatID,
          int? notificationID,
          int? customViewIndex,
          String? name,
          String? description,
          DateTime? startDate,
          DateTime? dueDate,
          DateTime? warnDate,
          DateTime? originalStart,
          DateTime? originalDue,
          DateTime? originalWarn,
          bool? warnMe,
          Priority? priority,
          bool? repeatable,
          RepeatableState? repeatableState,
          Frequency? frequency,
          List<bool>? repeatDays,
          int? repeatSkip,
          DateTime? lastUpdated}) =>
      Deadline(
          id: id ?? Constants.generateID(),
          repeatID: repeatID ?? this.repeatID,
          notificationID: notificationID ?? this.notificationID,
          customViewIndex: customViewIndex ?? this.customViewIndex,
          name: name ?? this.name,
          description: description ?? this.description,
          originalStart: originalStart ?? this.originalStart,
          originalDue: originalDue ?? this.originalDue,
          originalWarn: originalWarn ?? this.originalWarn,
          startDate: startDate ?? this.startDate,
          dueDate: dueDate ?? this.dueDate,
          warnDate: warnDate ?? this.warnDate,
          warnMe: warnMe ?? this.warnMe,
          priority: priority ?? this.priority,
          repeatable: repeatable ?? this.repeatable,
          frequency: frequency ?? this.frequency,
          repeatableState: repeatableState ?? this.repeatableState,
          repeatDays: (null != repeatDays)
              ? List.generate(repeatDays.length, (i) => repeatDays[i])
              : List.generate(
                  this.repeatDays.length, (i) => this.repeatDays[i]),
          repeatSkip: repeatSkip ?? this.repeatSkip,
          lastUpdated: lastUpdated ?? this.lastUpdated);

  @ignore
  @override
  List<Object?> get props => [id];

  @override
  String toString() =>
      "Deadline(id: $id, repeatID: $repeatID, customViewIndex: $customViewIndex,"
      " name: $name, description: $description, startDate: $startDate, "
      "dueDate $dueDate, warDate: $warnDate, originalStart: $originalStart, originalDue: $originalDue, originalWarn: $originalWarn,  warnMe: $warnMe, priority: "
      "${priority.name}, repeatable: $repeatable, frequency: ${frequency.name}, "
      "repeatDays: $repeatDays, repeatSkip: $repeatSkip, lastUpdated: $lastUpdated)";
}
