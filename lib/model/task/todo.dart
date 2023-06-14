import "package:equatable/equatable.dart";
import "../../util/numbers.dart";
import "deadline.dart";
import "repeat.dart";

enum Priority { low, medium, high }
enum Progress { assigned, inProgress, completed }

abstract class ToDo with EquatableMixin {
  String name;
  int weight;
  Duration expectedDuration;
  Priority priority;
  Progress progress = Progress.assigned;
  DeadLine deadline;
  Repeat repeat;


  ToDo({required this.name,
    this.weight = 0,
    this.expectedDuration = Duration.zero,
    this.priority = Priority.low,
    DateTime? startDate,
    DateTime? endDate,
    bool warnMe = false,
    Repeat? repeat}) :
      deadline = DeadLine(startDate: startDate, endDate: endDate, warnMe: warnMe),
      repeat = repeat ?? Repeat();

  Duration get realDuration {
    num factor = smoothstep(x: weight, v0: 1, v1: 10);
    return expectedDuration * factor;
  }

  @override
  List<Object> get props => [
    name,
    weight,
    expectedDuration,
    priority,
    progress,
    deadline,
    repeat
  ];
}
