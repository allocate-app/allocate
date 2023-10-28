import "package:equatable/equatable.dart";
import "package:isar/isar.dart";

import "../../util/constants.dart";
import "../../util/enums.dart";
import "../../util/interfaces/copyable.dart";
import "../../util/interfaces/i_repeatable.dart";

part "reminder.g.dart";

/// This is a simple reminder object for things that aren't a "task"
/// so much as they are a thing to remember.
@Collection(inheritance: false)
class Reminder with EquatableMixin implements Copyable<Reminder>, IRepeatable {
  @override
  @ignore
  ModelType modelType = ModelType.reminder;
  @override
  @ignore
  RepeatableType repeatableType = RepeatableType.reminder;

  @override
  @Index()
  Id id = Constants.generateID();
  @Index()
  int customViewIndex = -1;
  @Index()
  int? repeatID;
  @Index()
  int? notificationID;

  @override
  @Index()
  String name;

  @Ignore()
  @override
  DateTime get startDate => dueDate;

  @override
  set startDate(DateTime newDate) => dueDate = newDate;

  @Index()
  @override
  DateTime dueDate;
  @Index()
  bool repeatable;
  @override
  @Enumerated(EnumType.ordinal)
  Frequency frequency;
  List<bool> repeatDays;
  int repeatSkip;
  @Index()
  bool isSynced = false;
  @Index()
  bool toDelete = false;

  @override
  @Index()
  DateTime lastUpdated;

  Reminder(
      {this.repeatID,
      this.notificationID,
      required this.name,
      this.repeatable = false,
      required this.dueDate,
      required this.repeatDays,
      this.repeatSkip = 1,
      this.frequency = Frequency.once,
      required this.lastUpdated});

  @override
  Reminder copy() => Reminder(
      repeatID: repeatID,
      notificationID: notificationID,
      name: name,
      dueDate: dueDate,
      repeatable: repeatable,
      repeatDays: List.from(repeatDays),
      repeatSkip: repeatSkip,
      frequency: frequency,
      lastUpdated: lastUpdated);

  @override
  Reminder copyWith(
          {int? repeatID,
          int? notificationID,
          String? name,
          DateTime? dueDate,
          bool? repeatable,
          List<bool>? repeatDays,
          int? repeatSkip,
          Frequency? frequency,
          DateTime? lastUpdated}) =>
      Reminder(
          repeatID: repeatID ?? this.repeatID,
          notificationID: notificationID ?? this.notificationID,
          name: name ?? this.name,
          dueDate: dueDate ?? this.dueDate,
          repeatable: repeatable ?? this.repeatable,
          repeatDays: List.from(repeatDays ?? this.repeatDays),
          repeatSkip: repeatSkip ?? this.repeatSkip,
          frequency: frequency ?? this.frequency,
          lastUpdated: lastUpdated ?? this.lastUpdated);

  Reminder.fromEntity({required Map<String, dynamic> entity})
      : id = entity["id"] as Id,
        customViewIndex = entity["customViewIndex"] as int,
        repeatID = entity["repeatID"] as int?,
        notificationID = entity["notificationID"] as int?,
        name = entity["name"] as String,
        dueDate = DateTime.parse(entity["dueDate"]),
        frequency = Frequency.values[entity["frequency"]],
        repeatable = entity["repeatable"] as bool,
        repeatDays = entity["repeatDays"] as List<bool>,
        repeatSkip = entity["repeatSkip"] as int,
        isSynced = true,
        toDelete = false,
        lastUpdated = DateTime.parse(entity["lastUpdated"]);

  Map<String, dynamic> toEntity() => {
        "id": id,
        "customViewIndex": customViewIndex,
        "repeatID": repeatID,
        "notificationID": notificationID,
        "name": name,
        "dueDate": dueDate.toIso8601String(),
        "frequency": frequency.index,
        "repeatable": repeatable,
        "repeatDays": repeatDays,
        "repeatSkip": repeatSkip,
        "lastUpdated": lastUpdated
      };

  @ignore
  @override
  List<Object?> get props => [id];

  @override
  String toString() => "Reminder(id: $id, notificationID: $notificationID, "
      "repeatID: $repeatID,"
      "customViewIndex: $customViewIndex, name: $name,"
      "dueDate: $dueDate "
      "frequency: ${frequency.name}, "
      " repeatable: $repeatable, repeatDays: $repeatDays,"
      " repeatSkip: $repeatSkip,"
      " isSynced: $isSynced, toDelete: $toDelete)";
}
