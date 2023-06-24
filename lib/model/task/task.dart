import "../../util/interfaces/copyable";
import "todo.dart";


/// This is a concrete, instantiable ToDo, representing
/// the most basic sort of "to do" meant to be handled in a day or so.

class Task extends ToDo implements Copyable<Task> {
  Task(
      {required super.id,
        required super.name,
        required super.description,
        super.weight = 0,
        required super.expectedDuration,
        super.priority = Priority.low,
        super.startDate,
        super.endDate,
        super.focusTask = false,
        super.repeatable = false});

  @override
  Task copy() => Task(
        id: id,
        name: name,
        description: description,
        weight: weight,
        expectedDuration: expectedDuration,
        priority: priority,
        startDate: startDate,
        endDate: endDate,
        focusTask: focusTask,
        repeatable: repeatable,
  );
  @override
  Task copyWith({int? id, String? name, String? description, int? weight, Duration? expectedDuration, Priority? priority, DateTime? startDate, DateTime? endDate, bool? focusTask, bool? repeatable}) => Task(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        weight: weight ?? this.weight,
        expectedDuration: expectedDuration ?? this.expectedDuration,
        priority: priority ?? this.priority,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        focusTask: focusTask ?? this.focusTask,
        repeatable: repeatable ?? this.repeatable,
  );

}


