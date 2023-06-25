import "todocollection.dart";
import "routinetodo.dart";
import "todo.dart";
import "repeat.dart";


//TODO: REIMPLEMENT THIS ENTIRELY.
// THIS SHOULD HAVE SUBTASKS.
// FACTOR IT OUT.
class Routine extends ToDo with ToDoCollection<RoutineToDo>{
  static const maxTasksPerRoutine = 10;
  int numMorn = 0;
  int numAft = 0;
  int numEve = 0;

  // This ^^ may be best handled via a RoutineViewModel.
  Routine({required super.name, super.weight = 0, super.priority = Priority.high})
  {
    repeat = Repeat(frequency: Frequency.daily);
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
    expectedDuration += d;
    if(expectedDuration.isNegative)
    {
      expectedDuration = Duration.zero;
    }
  }
  void recalculateDuration() => expectedDuration = calculateDuration();

  List<RoutineToDo> get morning => [...todos.where((rt) => rt.timeOfDay == RoutineTime.morning)];
  List<RoutineToDo> get afternoon => [... todos.where((rt) => rt.timeOfDay == RoutineTime.afternoon)];
  List<RoutineToDo> get evening => [... todos.where((rt) => rt.timeOfDay == RoutineTime.evening)];

  @override
  List<Object> get props => super.props..add([todos]);
}



