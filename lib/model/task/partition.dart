import 'package:allocate/model/task/todo.dart';

class Partition extends ToDo {
  // This should hold a reference to the task from which it is.
  // And if it's from a subtask/task.

  // If from subtask, remove the subtask.
  // If from task, decrement the weight.
  // TODO: implement.
  Partition({required super.taskID, required super.name});
  // Uh, lol. Named Constructors only?
  Partition.fromTask();
  Partition.fromSubTask();
}