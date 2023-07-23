import "package:equatable/equatable.dart";
import "package:isar/isar.dart";

import "../../util/enums.dart";
import "../../util/interfaces/copyable.dart";

part "reminder.g.dart";

/// This is a simple reminder object for things that aren't a "task"
/// so much as they are a thing to remember.
/// TODO: remove comparable. Database will handle sorting.
/// TODO: add repeatable logic once ToDo is finished.
@Collection(inheritance: false)
class Reminder with EquatableMixin implements Copyable<Reminder> {
  Id id = Isar.autoIncrement;
  @Index()
  int customViewIndex = -1;
  @Index()
  String name;

  DateTime startDate;
  @Index()
  DateTime dueDate;
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

  Reminder(
      {this.repeatID,
      required this.name,
      this.repeatable = false,
      required this.startDate,
      required this.dueDate,
      required this.repeatDays,
      this.repeatSkip = 1,
      this.frequency = Frequency.once,
      this.customFreq = CustomFrequency.weekly});

  @override
  Reminder copy() => Reminder(
        repeatID: repeatID,
        name: name,
        startDate: startDate,
        dueDate: dueDate,
        repeatable: repeatable,
        repeatDays: List.from(repeatDays),
        repeatSkip: repeatSkip,
      );
  @override
  Reminder copyWith(
          {int? repeatID,
          String? name,
          DateTime? startDate,
          DateTime? dueDate,
          bool? repeatable,
          List<bool>? repeatDays,
          int? repeatSkip,
          Frequency? frequency,
          CustomFrequency? customFreq}) =>
      Reminder(
          repeatID: repeatID ?? this.repeatID,
          name: name ?? this.name,
          startDate: startDate ?? this.startDate,
          dueDate: dueDate ?? this.dueDate,
          repeatable: repeatable ?? this.repeatable,
          repeatDays: List.from(repeatDays ?? this.repeatDays),
          repeatSkip: repeatSkip ?? this.repeatSkip,
          frequency: frequency ?? this.frequency,
          customFreq: customFreq ?? this.customFreq);

  Reminder.fromEntity({required Map<String, dynamic> entity})
      : repeatID = entity["repeatID"] as int?,
        id = entity["id"] as Id,
        customViewIndex = entity["customViewIndex"] as int,
        name = entity["name"] as String,
        startDate = DateTime.parse(entity["startDate"]),
        dueDate = DateTime.parse(entity["dueDate"]),
        frequency = Frequency.values[entity["frequency"]],
        customFreq = CustomFrequency.values[entity["customFrequency"]],
        repeatable = entity["repeatable"] as bool,
        repeatDays = entity["repeatDays"] as List<bool>,
        repeatSkip = entity["repeatSkip"] as int;

  Map<String, dynamic> toEntity() => {
        "repeatID": repeatID,
        "id": id,
        "customViewIndex": customViewIndex,
        "name": name,
        "startDate": startDate.toIso8601String(),
        "dueDate": dueDate.toIso8601String(),
        "frequency": frequency.index,
        "customFreq": customFreq.index,
        "repeatable": repeatable,
        "repeatDays": repeatDays,
        "repeatSkip": repeatSkip,
      };

  @ignore
  @override
  List<Object> get props =>
      [name, dueDate, customViewIndex, isSynced, toDelete];
}
