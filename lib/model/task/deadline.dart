import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';

import '../../util/enums.dart';
import '../../util/interfaces/copyable.dart';
import '../../util/interfaces/i_model.dart';

/// DeadLines are meant for large-projects that have a due-date. They are just the project description
/// and that alone, so as to not overwhelm with the temptation of overloading subtasks.

part "deadline.g.dart";

@Collection(inheritance: false)
class Deadline with EquatableMixin implements Copyable<Deadline>, IModel {
  @ignore
  @override
  int? localID;

  Id id = Isar.autoIncrement;
  @Index()
  int customViewIndex;
  @Index()
  int? repeatID;
  @Index()
  int? notificationID;
  @override
  @Index()
  String name;
  String description;

  DateTime startDate;
  @Index()
  DateTime dueDate;
  DateTime warnDate;
  @Index()
  bool warnMe;

  @Enumerated(EnumType.ordinal)
  Priority priority;

  @Index()
  bool repeatable;
  @Enumerated(EnumType.ordinal)
  Frequency frequency;
  List<bool> repeatDays;
  int repeatSkip;

  @Index()
  bool isSynced = false;
  @Index()
  bool toDelete = false;

  @Index()
  DateTime lastUpdated;

  Deadline(
      {this.repeatID,
      this.notificationID,
      this.customViewIndex = -1,
      required this.name,
      this.description = "",
      required this.startDate,
      required this.dueDate,
      required this.warnDate,
      this.warnMe = false,
      this.priority = Priority.low,
      this.repeatable = false,
      this.frequency = Frequency.once,
      required this.repeatDays,
      this.repeatSkip = 1,
      required this.lastUpdated});

  Deadline.fromEntity({required Map<String, dynamic> entity})
      : id = entity["id"] as Id,
        customViewIndex = entity["customViewIndex"] as int,
        repeatID = entity["repeatID"] as int?,
        notificationID = entity["notificationID"] as int?,
        name = entity["name"] as String,
        description = entity["description"] as String,
        startDate = DateTime.parse(entity["startDate"]),
        dueDate = DateTime.parse(entity["dueDate"]),
        warnDate = DateTime.parse(entity["warnDate"]),
        warnMe = entity["warnMe"] as bool,
        priority = Priority.values[entity["priority"]],
        repeatable = entity["repeatable"],
        frequency = Frequency.values[entity["frequency"]],
        repeatDays = entity["repeatDays"] as List<bool>,
        repeatSkip = entity["repeatSkip"] as int,
        lastUpdated = DateTime.parse(entity["lastUpdated"]),
        isSynced = true,
        toDelete = false;

  // No id for syncing - assigned via autoincrement online.
  Map<String, dynamic> toEntity() => {
        "customViewIndex": customViewIndex,
        "notificationID": notificationID,
        "name": name,
        "description": description,
        "startDate": startDate.toIso8601String(),
        "dueDate": dueDate.toIso8601String(),
        "warnDate": warnDate.toIso8601String(),
        "warnMe": warnMe,
        "priority": priority.index,
        "repeatable": repeatable,
        "frequency": frequency.index,
        "repeatDays": repeatDays,
        "repeatSkip": repeatSkip,
        "lastUpdated": lastUpdated.toIso8601String()
      };

  @override
  Deadline copy() => Deadline(
        notificationID: notificationID,
        repeatID: repeatID,
        customViewIndex: customViewIndex,
        name: name,
        description: description,
        startDate: startDate,
        dueDate: dueDate,
        warnDate: warnDate,
        warnMe: warnMe,
        priority: priority,
        repeatable: repeatable,
        frequency: frequency,
        repeatDays: List.from(repeatDays),
        repeatSkip: repeatSkip,
        lastUpdated: lastUpdated,
      );

  @override
  Deadline copyWith(
          {int? repeatID,
          int? notificationID,
          int? customViewIndex,
          String? name,
          String? description,
          DateTime? startDate,
          DateTime? dueDate,
          DateTime? warnDate,
          bool? warnMe,
          Priority? priority,
          bool? repeatable,
          Frequency? frequency,
          List<bool>? repeatDays,
          int? repeatSkip,
          DateTime? lastUpdated}) =>
      Deadline(
          repeatID: repeatID ?? this.repeatID,
          notificationID: notificationID ?? this.notificationID,
          customViewIndex: customViewIndex ?? this.customViewIndex,
          name: name ?? this.name,
          description: description ?? this.description,
          startDate: startDate ?? this.startDate,
          dueDate: dueDate ?? this.dueDate,
          warnDate: warnDate ?? this.warnDate,
          warnMe: warnMe ?? this.warnMe,
          priority: priority ?? this.priority,
          repeatable: repeatable ?? this.repeatable,
          frequency: frequency ?? this.frequency,
          repeatDays: List.from(repeatDays ?? this.repeatDays),
          repeatSkip: repeatSkip ?? this.repeatSkip,
          lastUpdated: lastUpdated ?? this.lastUpdated);

  @ignore
  @override
  List<Object?> get props => [
        // TODO: This is a current race condition in testing.
        // ID should be able to be returned once built.
        //id,
        notificationID,
        name,
        description,
        startDate,
        dueDate,
        warnDate,
        warnMe,
        priority,
        repeatable,
        frequency,
        repeatDays,
        repeatSkip,
        lastUpdated,
      ];

  @override
  String toString() =>
      "Deadline(id: $id, repeatID: $repeatID, customViewIndex: $customViewIndex,"
      " name: $name, description: $description, startDate: $startDate, "
      "dueDate $dueDate, warDate: $warnDate, warnMe: $warnMe, priority: "
      "${priority.name}, repeatable: $repeatable, frequency: ${frequency.name}, "
      "repeatDays: $repeatDays, repeatSkip: $repeatSkip, lastUpdated: $lastUpdated)";
}
