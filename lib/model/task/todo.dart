import "package:equatable/equatable.dart";
import "../../util/numbers.dart";

enum Priority { low, medium, high }
abstract class ToDo with EquatableMixin implements Comparable<ToDo> {
  // To set the id in todoservice once db is handled.
  // SOMETHING akin to this:
  // FirebaseFirestore.instance.collection("tablename").doc().id;
  int taskID;
  int? groupID;
  String name;
  String description;
  int weight;
  Duration expectedDuration;
  Priority priority;
  bool completed = false;
  DateTime dueDate;
  bool focusTask;
  // TODO: repeat stuff. Not quite sure how to implement this yet.
  bool repeatable;


  ToDo(
      {required this.taskID,
      this.groupID,
      required this.name,
      this.description = "",
      this.weight = 0,
      this.expectedDuration = Duration.zero,
      this.priority = Priority.low,
      DateTime? dueDate,
      this.focusTask = false,
      this.repeatable = false}): dueDate = dueDate ?? DateTime.now();

  Duration get realDuration {
    num factor = smoothstep(x: weight, v0: 1, v1: 10);
    return expectedDuration * factor;
  }

  @override
  int compareTo(ToDo t2) => name.compareTo(t2.name);

  @override
  List<Object> get props =>
      [taskID, name, description, weight, expectedDuration, priority, completed, dueDate, focusTask, repeatable];
}
