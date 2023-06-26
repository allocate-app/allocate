import "package:equatable/equatable.dart";

/// This is a simple reminder object for things that aren't a "task"
/// so much as they are a thing to remember.

class Reminder with EquatableMixin implements Comparable<Reminder> {
  int reminderID;
  String name;
  DateTime dueDate;
  Reminder({required this.reminderID, required this.name, DateTime? dueDate}):
      dueDate = dueDate ?? DateTime.now();

  @override
  int compareTo(Reminder r2) => dueDate.compareTo(r2.dueDate);

  @override
  List<Object> get props => [name, dueDate];

}