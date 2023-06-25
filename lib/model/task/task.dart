import "../../util/interfaces/copyable.dart";
import "todo.dart";


/// This is a concrete, instantiable ToDo, representing
/// the most basic sort of "to do" meant to be handled in a day or so.

// This may need to implement a serializable interface.
class Task extends ToDo implements Copyable<Task> {
  Task(
      {required super.taskID,
        super.groupID,
        required super.name,
        super.description,
        super.weight = 0,
        super.expectedDuration,
        super.priority = Priority.low,
        super.dueDate,
        super.focusTask = false,
        super.repeatable = false});

  @override
  Task copy() => Task(
        taskID: taskID,
        groupID: groupID,
        name: name,
        description: description,
        weight: weight,
        expectedDuration: expectedDuration,
        priority: priority,
        dueDate: dueDate,
        focusTask: focusTask,
        repeatable: repeatable,
  );
  @override
  Task copyWith({int? taskID, int? groupID, String? name, String? description, int? weight, Duration? expectedDuration, Priority? priority, DateTime? dueDate, bool? focusTask, bool? repeatable}) => Task(
        taskID: taskID ?? this.taskID,
        groupID: groupID ?? this.groupID,
        name: name ?? this.name,
        description: description ?? this.description,
        weight: weight ?? this.weight,
        expectedDuration: expectedDuration ?? this.expectedDuration,
        priority: priority ?? this.priority,
        dueDate: dueDate ?? this.dueDate,
        focusTask: focusTask ?? this.focusTask,
        repeatable: repeatable ?? this.repeatable,
  );

}


