import "package:equatable/equatable.dart";

import "deadline.dart";
/// This is a simple reminder object for things that aren't a "task"
/// so much as they are a thing to remember.

// TODO: This could be a deadline -> consider refactoring?

class Reminder with EquatableMixin implements Comparable<Reminder> {
  String name;
  DeadLine deadline;
  Reminder({required this.name, DateTime? startDate, DateTime? endDate, bool warnMe = true}):
      deadline = DeadLine(startDate: startDate, endDate: endDate, warnMe: warnMe);

  @override
  int compareTo(Reminder r2) => deadline.endDate.compareTo(r2.deadline.endDate);

  @override
  List<Object> get props => [name, deadline];

}