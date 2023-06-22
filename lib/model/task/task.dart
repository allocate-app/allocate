import "todo.dart";


/// This is a concrete, instantiable ToDo, representing
/// the most basic sort of "to do" meant to be handled in a day or so.

class Task extends ToDo {
  Task(
      {required super.name,
      super.weight,
      super.expectedDuration,
      super.priority,
      super.startDate,
      super.endDate,
      super.warnMe = false,
      super.myDay,
      super.repeat});
}


