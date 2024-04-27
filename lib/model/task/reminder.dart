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
  Fade fade = Fade.none;

  @override
  @Index()
  late Id id;
  late int customViewIndex;
  @override
  @Index()
  int? repeatID;
  @Index()
  int? notificationID;

  @override
  @Index()
  String name;

  @Ignore()
  @override
  DateTime? get startDate => dueDate;

  @override
  set startDate(DateTime? newDate) => dueDate = newDate;

  @override
  DateTime? get originalStart => originalDue;

  @override
  set originalStart(DateTime? newDate) => originalDue = newDate;

  @Index()
  @override
  DateTime? originalDue;

  @Index()
  @override
  DateTime? dueDate;

  @override
  @Index()
  bool repeatable;
  @override
  @Enumerated(EnumType.ordinal)
  Frequency frequency;
  @override
  @Index()
  @Enumerated(EnumType.ordinal)
  RepeatableState repeatableState;
  @override
  List<bool> repeatDays;
  @override
  int repeatSkip;
  @override
  @Index()
  late bool isSynced;
  @override
  @Index()
  late bool toDelete;

  @override
  DateTime lastUpdated;

  Reminder(
      {required this.id,
      this.repeatID,
      this.notificationID,
      this.customViewIndex = -1,
      required this.name,
      this.repeatable = false,
      this.repeatableState = RepeatableState.normal,
      this.dueDate,
      this.originalDue,
      required this.repeatDays,
      this.repeatSkip = 1,
      this.frequency = Frequency.once,
      this.toDelete = false,
      this.isSynced = false,
      required this.lastUpdated});

  @override
  Reminder copy() => Reminder(
      id: Constants.generateID(),
      repeatID: repeatID,
      notificationID: notificationID,
      customViewIndex: customViewIndex,
      name: name,
      dueDate: dueDate,
      originalDue: originalDue,
      repeatable: repeatable,
      repeatDays: List.generate(repeatDays.length, (i) => repeatDays[i]),
      repeatSkip: repeatSkip,
      frequency: frequency,
      repeatableState: repeatableState,
      lastUpdated: DateTime.now());

  @override
  Reminder copyWith(
          {int? id,
          int? repeatID,
          int? notificationID,
          String? name,
          DateTime? dueDate,
          DateTime? originalDue,
          bool? repeatable,
          List<bool>? repeatDays,
          int? repeatSkip,
          Frequency? frequency,
          RepeatableState? repeatableState,
          bool? isSynced,
          DateTime? lastUpdated}) =>
      Reminder(
          id: id ?? Constants.generateID(),
          repeatID: repeatID ?? this.repeatID,
          notificationID: notificationID ?? this.notificationID,
          name: name ?? this.name,
          dueDate: dueDate ?? this.dueDate,
          originalDue: originalDue ?? this.originalDue,
          repeatable: repeatable ?? this.repeatable,
          repeatDays: (null != repeatDays)
              ? List.generate(repeatDays.length, (i) => repeatDays[i])
              : List.generate(
                  this.repeatDays.length, (i) => this.repeatDays[i]),
          repeatableState: repeatableState ?? this.repeatableState,
          repeatSkip: repeatSkip ?? this.repeatSkip,
          frequency: frequency ?? this.frequency,
          lastUpdated: lastUpdated ?? DateTime.now(),
          isSynced: isSynced ?? false);

  Reminder.fromEntity({required Map<String, dynamic> entity})
      : id = entity["id"] as Id,
        customViewIndex = entity["customViewIndex"] as int,
        repeatID = entity["repeatID"] as int?,
        notificationID = entity["notificationID"] as int?,
        name = entity["name"] as String,
        dueDate = DateTime.tryParse(entity["dueDate"] ?? ""),
        originalDue = DateTime.tryParse(entity["originalDue"] ?? ""),
        frequency = Frequency.values[entity["frequency"]],
        repeatableState = RepeatableState.values[entity["repeatableState"]],
        repeatable = entity["repeatable"] as bool,
        repeatDays = List.generate(7, (i) => entity["repeatDays"][i]),
        repeatSkip = entity["repeatSkip"] as int,
        isSynced = true,
        toDelete = entity["toDelete"] as bool,
        lastUpdated =
            DateTime.tryParse(entity["lastUpdated"] ?? "") ?? Constants.today;

  Map<String, dynamic> toEntity() => {
        "id": id,
        "customViewIndex": customViewIndex,
        "repeatID": repeatID,
        "notificationID": notificationID,
        "name": name,
        "dueDate": (null != dueDate) ? dueDate!.toIso8601String() : dueDate,
        "originalDue": (null != originalDue)
            ? originalDue!.toIso8601String()
            : originalDue,
        "frequency": frequency.index,
        "repeatable": repeatable,
        "repeatableState": repeatableState.index,
        "repeatDays": repeatDays,
        "repeatSkip": repeatSkip,
        "toDelete": toDelete,
        "lastUpdated": lastUpdated.toIso8601String(),
      };

  @ignore
  @override
  List<Object?> get props => [id];

  @override
  String toString() => "Reminder(id: $id, notificationID: $notificationID, "
      "repeatID: $repeatID,"
      "customViewIndex: $customViewIndex, name: $name,"
      "dueDate: $dueDate "
      "frequency: ${frequency.name},  originalDue: $originalDue"
      " repeatable: $repeatable, repeatDays: $repeatDays,"
      " repeatSkip: $repeatSkip,"
      " isSynced: $isSynced, toDelete: $toDelete)";
}
