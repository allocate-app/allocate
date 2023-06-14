import "package:equatable/equatable.dart";

import "deadline.dart";
/// This is a simple reminder object for things that aren't a "task"
/// so much as they are a thing to remember.


class Reminder with EquatableMixin {
  String name;
  DeadLine deadline;
  Reminder({required this.name, DateTime? startDate, DateTime? endDate, bool warnMe = true}):
      deadline = DeadLine(startDate: startDate, endDate: endDate, warnMe: warnMe);

  @override
  List<Object> get props => [name, deadline];
}