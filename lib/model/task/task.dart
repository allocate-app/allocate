import 'dart:convert';
import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:event/event.dart';
import 'dart:io';


enum Priority{low, medium, high}
enum Progress{assigned, inProgress, completed}
enum Frequency{none, daily, weekly, monthly, yearly}

mixin DeadLine{
  DateTime? startDate;
  DateTime? endDate;

  // TODO: Set up local notifications.
  // void method to initialize.
  // void method to update the date.
  // Call these from a delegate class that interfaces with the UI.

}

mixin TaskCollection{
  final _todos = <ToDo>[];
  final _completes = <ToDo>[];
  var sc = StreamController();

  List<ToDo> get todos => _todos;
  List<ToDo> get completes => _completes;
  bool _addTask(ToDo task)
  {
    if(_todos.contains(task))
      {
        return false;
      }
    if(task is Completable<ToDo>)
    {
      var c = task as Completable<ToDo>;
      c.onComplete + (t) => completeTask(t!.task);
    }
    _todos.add(task);

    return true;
  }
  bool _removeTask(ToDo task)
  {
    if(!_todos.remove(task))
    {
      return false;
    }
    return true;
  }

    bool completeTask(ToDo task)
    {
      if(!_removeTask(task))
      {
        return false;
      }
      _completes.add(task);
      if(task is Completable<ToDo>)
        {
          var c = task as Completable<ToDo>;
          c.onComplete - (t) => completeTask(t!.task);
        }

      return true;
    }
    // Lol. Refactor this.
    bool unCompleteTask(ToDo task)
    {
      if(!_completes.remove(task))
      {
        return false;
      }
      return _addTask(task);
    }

    bool reOrderTask(ToDo task, int index)
    {
      if(!_removeTask(task))
      {
        return false;
      }

      _todos.insert(index, task);
      return true;
    }

    void sortByName() => _todos.sort();
    void sortByWeight() => _todos.sort((a, b) => a.weight.compareTo(b.weight));
    void sortByPriority() => _todos.sort((a, b) => a.priority.index.compareTo(b.priority.index));
    void sortByDate() => _todos.sort((a, b) => a.endDate!.compareTo(b.endDate!));
}

interface class Completable<ToDo>{
  final onComplete = Event<ToDoComplete>();
  void broadcastComplete() => onComplete.broadcast();
}

abstract class ToDo with DeadLine, EquatableMixin implements Comparable<ToDo> {
  String name;
  int weight;
  Duration expectedDuration;
  Priority priority;
  Progress progress = Progress.assigned;
  Repeat? repeater;

  ToDo({required this.name, this.weight = 0, this.expectedDuration = Duration.zero, this.priority = Priority.low, DateTime? startDate, DateTime? endDate, this.repeater})
  {
    this.startDate = startDate;
    this.endDate = endDate;
  }

  Duration get realDuration {
    // TODO: Refactor to use a weighted multiplier.
    int factor = (weight > 0) ? weight : 1;
    return expectedDuration * factor;
  }

  @override
  int compareTo(ToDo t2) => name.compareTo(t2.name);

  @override
  List<Object> get props => [name, weight, priority, progress, startDate.toString(), endDate.toString()];
}

class ToDoComplete extends EventArgs
{
  ToDo task;
  ToDoComplete(this.task);
}


class Task extends ToDo implements Completable<Task>{
  Task({required super.name, super.weight, super.expectedDuration, super.priority, super.startDate, super.endDate});
  @override
  final onComplete = Event<ToDoComplete>();

  @override
  set progress(Progress state)
  {
    if(state == Progress.completed)
      {
        broadcastComplete();
      }
    super.progress = state;
  }
  @override
  void broadcastComplete() => onComplete.broadcast(ToDoComplete(this));


}
class LargeTask extends ToDo with DeadLine, TaskCollection implements Completable<LargeTask> {
  final maxSubTasks = 5;
  LargeTask({required super.name, super.priority, super.startDate, super.endDate});

  @override
  final onComplete = Event<ToDoComplete>();

  @override
  set progress(Progress state)
  {

    if(state != Progress.completed)
      {
        super.progress = state;
        return;
      }

    if(todos.isNotEmpty)
    {
      state = confirmFinished();
    }

    if(state == Progress.completed)
      {
        broadcastComplete();
      }

    super.progress == state;
  }
  @override
  void broadcastComplete() => onComplete.broadcast(ToDoComplete(this));

  Progress confirmFinished()
  {
    //REMOVE => refactor into async method.
      print("Resolve all subtasks?");
      var input = stdin.readLineSync(encoding: utf8);
      print(input);
      if(input == 'y')
        {
          while(todos.isNotEmpty)
            {
              todos.first.progress = Progress.completed;
            }
          return Progress.completed;
        }
      return Progress.inProgress;
  }
  // TODO: Error handling. Async + Db stuff.
  bool addSubTask(Task task)
  {
    if(todos.length > maxSubTasks)
      {
        return false;
      }

    if(!_addTask(task))
      {
        return false;
      }
    updateWeight(task.weight);
    return true;
  }
  bool removeSubTask(Task task)
  {
    if(!_removeTask(task))
      {
        return false;
      }
    updateWeight(-task.weight);
    return true;
  }
  bool completeSubTask(Task task)
  {
    if(!completeTask(task))
      {
        return false;
      }
    updateWeight(-task.weight);
    return true;
  }
  void updateWeight(int w){weight += w; weight = (weight > 0) ? weight : 0;}
  void recalculateWeight() => {weight = _todos.fold(0, (p, c) => p + c.weight)};

  @override
  List<Object> get props => super.props..add([maxSubTasks, todos, completes]);
}

class Reminder with DeadLine {
  String name;
  Reminder({required this.name, DateTime? startDate, DateTime? endDate})
  {
    this.startDate = startDate;
    this.endDate = endDate;
  }
}

class Repeat
{
  // Calculated from start date.
  int? numDays;
  bool? custom;
  DateTime? startDate;
  DateTime? endDate;
  Frequency repeatFactor;

  Repeat({this.numDays = 1, this.custom = false, this.startDate, this.endDate, this.repeatFactor = Frequency.none});

  // Should probably have some sort of DateTime listener for the endDate.
  // TODO: design this.
  void endRepeat()
  {
    repeatFactor = Frequency.none;
}

}