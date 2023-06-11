import "todostates.dart";

/// This is a simple reminder object for things that aren't a "task"
/// so much as they are a thing to remember.

import "deadline.dart";
class Reminder with DeadLine, ModelState<Reminder> {
  String name;
  Reminder({required this.name, DateTime? startDate, DateTime? endDate}) {
    this.startDate = (null != startDate) ? startDate: DateTime.now();

    // Usually reminders are at least one day out.
    this.endDate = (null != endDate) ? endDate : DateTime.now().add(const Duration(days: 1));
  }
}