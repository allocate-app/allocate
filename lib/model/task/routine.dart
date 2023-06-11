import "todocollection.dart";
import "routinetodo.dart";
import "todo.dart";
import "repeat.dart";

class Routine extends ToDo with ToDoCollection<RoutineToDo>{
  static const maxTasksPerRoutine = 10;
  Routine({required super.name, super.weight = 0, super.priority = Priority.high})
  {
    repeater = Repeat(repeatFactor: Frequency.weekly);
  }

  void resetRoutine()
  {
    for(ToDo rt in todos)
      {
        rt.progress = Progress.assigned;
      }
  }

  void updateWeight(int w) => weight = (weight + w > 0) ? weight + w : 0;
  void recalculateWeight() => weight = calculateWeight();
  void updateDuration(Duration d, bool add)
  {
    expectedDuration = (add)? expectedDuration + d : expectedDuration - d;
    if(expectedDuration.isNegative)
    {
      expectedDuration = Duration.zero;
    }
  }
  void recalculateDuration() => expectedDuration = calculateDuration();

  List<RoutineToDo> get morning => [...todos.where((rt) => rt.timeOfDay == RoutineTime.morning)];
  List<RoutineToDo> get afternoon => [... todos.where((rt) => rt.timeOfDay == RoutineTime.afternoon)];
  List<RoutineToDo> get evening => [... todos.where((rt) => rt.timeOfDay == RoutineTime.evening)];

  // Needs a bubble up for state changes.
}



