import "task.dart";

enum RoutineTime{morning, afternoon, evening}

class Routine extends ToDo{
  static const maxTasksPerRoutine = 10;
  final _morning = <RoutineTask>[];
  final _afternoon = <RoutineTask>[];
  final _evening = <RoutineTask>[];

  Routine({required super.name, super.weight = 0, super.priority = Priority.high,})
  {
    repeater = Repeat(repeatFactor: Frequency.weekly);
  }

  List<RoutineTask> get morning => _morning;
  List<RoutineTask> get afternoon => _afternoon;
  List<RoutineTask> get evening => _evening;

  bool addRoutineTask(RoutineTask task)
  {
    List<RoutineTask> routine = switch(task.timeOfDay)
    {
      RoutineTime.morning => _morning,
      RoutineTime.afternoon => _afternoon,
      _ => _evening
    };

    if(routine.length > maxTasksPerRoutine)
      {
        return false;
      }

    updateWeight(task.weight);
    return true;
  }

  bool removeRoutineTask(RoutineTask task, RoutineTime time)
  {
    switch(time){
      case RoutineTime.morning:
        if(!_morning.remove(task))
        {
          return false;
        }
        break;

      case RoutineTime.evening:
        if(!_evening.remove(task))
        {
          return false;
        }
        break;
      default:
        if(!_afternoon.remove(task))
        {
          return false;
        }
        break;
    }
    updateWeight(-task.weight);
    return true;
  }


  void updateWeight(int w)
  {
    weight += w;
  }
  void recalculateWeight()
  {
    weight = _morning.fold(0, (p, c) => p + c.weight);
    weight += _afternoon.fold(0, (p, c) => p + c.weight);
    weight += _evening.fold(0, (p, c) => p + c.weight);
  }
}

class RoutineTask extends ToDo
{
  RoutineTime timeOfDay;
  RoutineTask({required super.name, super.weight, super.expectedDuration, super.priority = Priority.high, super.startDate, super.endDate, this.timeOfDay = RoutineTime.afternoon});
}