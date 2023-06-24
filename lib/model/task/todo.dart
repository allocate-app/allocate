import "package:equatable/equatable.dart";
import "../../util/numbers.dart";
import "repeat.dart";

enum Priority { low, medium, high }

abstract class ToDo with EquatableMixin implements Comparable<ToDo> {
  // To set the id in todoservice once db is handled.
  // SOMETHING akin to this:
  // FirebaseFirestore.instance.collection("tablename").doc().id;
  int id;
  String name;
  String description;
  int weight;
  Duration expectedDuration;
  Priority priority;
  bool completed = false;
  // TODO: refactor start date out. Isn't necessary. Move to projects/deadlines.
  DateTime startDate;
  DateTime endDate;
  bool focusTask;
  bool repeatable;

  // TODO: redefine this later.
  Repeat? repeat;

  ToDo(
      {required this.id,
      required this.name,
      required this.description,
      this.weight = 0,
      this.expectedDuration = Duration.zero,
      this.priority = Priority.low,
      DateTime? startDate,
      DateTime? endDate,
      this.focusTask = false,
      this.repeatable = false})
      : startDate = startDate ?? DateTime.now(),
        endDate = endDate ?? DateTime.now();

  Duration get realDuration {
    num factor = smoothstep(x: weight, v0: 1, v1: 10);
    return expectedDuration * factor;
  }

  @override
  int compareTo(ToDo t2) => name.compareTo(t2.name);

  @override
  List<Object> get props =>
      [id, name, description, weight, expectedDuration, priority, completed, startDate, endDate, focusTask, repeatable];
}
