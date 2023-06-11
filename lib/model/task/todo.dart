import "package:event/event.dart";
import "deadline.dart";
import "repeat.dart";
import "../../util/numbers.dart";
import "package:equatable/equatable.dart";


enum Priority { low, medium, high }
enum Progress { assigned, inProgress, completed }

class StateChange extends EventArgs{

}

abstract class ToDo with DeadLine, EquatableMixin {
  String name;
  int weight;
  Duration expectedDuration;
  Priority priority;
  Progress progress = Progress.assigned;
  late Repeat repeater;


  ToDo({required this.name,
    this.weight = 0,
    this.expectedDuration = Duration.zero,
    this.priority = Priority.low,
    DateTime? startDate,
    DateTime? endDate,
    bool warnMe = false,
    Repeat? repeat}) {
    if(null != startDate)
      {
        this.startDate = startDate;
      }
    if(null != endDate)
      {
        this.endDate = endDate;
      }
    repeater = (null != repeat)? repeat : Repeat();

    this.warnMe = warnMe;
  }

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
    warnMe,
    repeater,
    startDate,
    endDate,
  ];
}
