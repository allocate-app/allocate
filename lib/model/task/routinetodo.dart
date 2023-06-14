import "todo.dart";

enum RoutineTime { morning, afternoon, evening }

class RoutineToDo extends ToDo {
  RoutineTime timeOfDay;
  RoutineToDo(
      {required super.name,
      super.weight,
      super.expectedDuration,
      super.priority = Priority.high,
      super.startDate,
      super.endDate,
      this.timeOfDay = RoutineTime.morning,
      super.repeat});

  @override
  List<Object> get props => super.props..add(timeOfDay);
}
