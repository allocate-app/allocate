import "package:equatable/equatable.dart";
import "package:isar/isar.dart";

import "../../util/enums.dart";
import "../../util/interfaces/copyable.dart";

part "reminder.g.dart";

/// This is a simple reminder object for things that aren't a "task"
/// so much as they are a thing to remember.
@Collection(inheritance: false)
class Reminder with EquatableMixin implements Copyable<Reminder> {
  Id id = Isar.autoIncrement;
  @Index()
  int customViewIndex = -1;
  // @Index()
  // int? repeatID;
  @Index()
  int? notificationID;

  @Index()
  String name;

  @Index()
  DateTime dueDate;
  // Removing repeatable stuff for now
  // @Index()
  // bool repeatable;
  // @Enumerated(EnumType.ordinal)
  // Frequency frequency;
  // @Enumerated(EnumType.ordinal)
  // CustomFrequency customFreq;
  // List<bool> repeatDays;
  // int repeatSkip;
  @Index()
  bool isSynced = false;
  @Index()
  bool toDelete = false;
  @Index()
  DateTime lastUpdated;

  Reminder(
      {
      // this.repeatID,
      this.notificationID,
      required this.name,
      //this.repeatable = false,
      required this.dueDate,
      // required this.repeatDays,
      // this.repeatSkip = 1,
      // this.frequency = Frequency.once,
      // this.customFreq = CustomFrequency.weekly,
      required this.lastUpdated});

  @override
  Reminder copy() => Reminder(
      // repeatID: repeatID,
      notificationID: notificationID,
      name: name,
      dueDate: dueDate,
      //  repeatable: repeatable,
      //  repeatDays: List.from(repeatDays),
      // repeatSkip: repeatSkip,
      lastUpdated: lastUpdated);
  @override
  Reminder copyWith(
          {
            // int? repeatID,
          int? notificationID,
          String? name,
          DateTime? dueDate,
          // DateTime? warnDate,
          // bool? repeatable,
          // List<bool>? repeatDays,
          // int? repeatSkip,
          // Frequency? frequency,
          // CustomFrequency? customFreq,
          DateTime? lastUpdated}) =>
      Reminder(
          // repeatID: repeatID ?? this.repeatID,
          notificationID: notificationID ?? this.notificationID,
          name: name ?? this.name,
          dueDate: dueDate ?? this.dueDate,
          // repeatable: repeatable ?? this.repeatable,
          // repeatDays: List.from(repeatDays ?? this.repeatDays),
          // repeatSkip: repeatSkip ?? this.repeatSkip,
          // frequency: frequency ?? this.frequency,
          // customFreq: customFreq ?? this.customFreq,
          lastUpdated: lastUpdated ?? this.lastUpdated);

  Reminder.fromEntity({required Map<String, dynamic> entity})
      : id = entity["id"] as Id,
        customViewIndex = entity["customViewIndex"] as int,
        // repeatID = entity["repeatID"] as int?,
        notificationID = entity["notificationID"] as int?,
        name = entity["name"] as String,
        dueDate = DateTime.parse(entity["dueDate"]),
        // frequency = Frequency.values[entity["frequency"]],
        // customFreq = CustomFrequency.values[entity["customFrequency"]],
        // repeatable = entity["repeatable"] as bool,
        // repeatDays = entity["repeatDays"] as List<bool>,
        // repeatSkip = entity["repeatSkip"] as int,
        isSynced = true,
        toDelete = false,
        lastUpdated = DateTime.parse(entity["lastUpdated"]);

  Map<String, dynamic> toEntity() => {
        "customViewIndex": customViewIndex,
        // "repeatID": repeatID,
        "notificationID": notificationID,
        "name": name,
        "dueDate": dueDate.toIso8601String(),
        // "frequency": frequency.index,
        // "customFreq": customFreq.index,
        // "repeatable": repeatable,
        // "repeatDays": repeatDays,
        // "repeatSkip": repeatSkip,
        "lastUpdated": lastUpdated
      };

  @ignore
  @override
  List<Object?> get props => [
        // TODO: re-test once app built. Currently a race condition && nullptr due to testing widget.
        // id,
        notificationID,
        // repeatID,
        customViewIndex,
        name,
        dueDate,
        // frequency,
        // customFreq,
        // repeatable,
        // repeatDays,
        // repeatSkip,
        isSynced,
        toDelete
      ];
  @override
  String toString() =>
      "Reminder(id: $id, notificationID: $notificationID, "
          // "repeatID: $repeatID,"
      "customViewIndex: $customViewIndex, name: $name,"
      "dueDate: $dueDate "
      //     "frequency: ${frequency.name}, "
      // "customFreq: ${customFreq.name}, repeatable: $repeatable, repeatDays: $repeatDays,"
      // " repeatSkip: $repeatSkip,"
          " isSynced: $isSynced, toDelete: $toDelete)";
}
