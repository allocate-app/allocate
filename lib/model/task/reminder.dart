import "package:equatable/equatable.dart";
import "package:isar/isar.dart";
import "../../util/interfaces/copyable.dart";

/// This is a simple reminder object for things that aren't a "task"
/// so much as they are a thing to remember.
/// TODO: remove comparable. Database will handle sorting.
@collection
class Reminder with EquatableMixin implements Copyable<Reminder> {
  Id id = Isar.autoIncrement;
  int customViewIndex = -1;
  String name;
  DateTime dueDate;
  bool isSynced = true;
  bool toDelete = false;
  Reminder({required this.name, DateTime? dueDate})
      : dueDate = dueDate ?? DateTime.now();

  @override
  Reminder copy() => Reminder(name: name, dueDate: dueDate);
  @override
  Reminder copyWith({String? name, DateTime? dueDate}) =>
      Reminder(name: name ?? this.name, dueDate: dueDate ?? this.dueDate);

  Reminder.fromEntity({required Map<String, dynamic> entity})
      : id = entity["id"] as Id,
        customViewIndex = entity["customViewIndex"] as int,
        name = entity["name"] as String,
        dueDate = DateTime.parse(entity["dueDate"]);

  Map<String, dynamic> toEntity() =>
      {"id": id, "customViewIndex": customViewIndex, "name": name, "dueDate": dueDate.toIso8601String()};

  @override
  List<Object> get props => [name, dueDate, customViewIndex];
}
