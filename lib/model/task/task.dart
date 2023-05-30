import 'dart:convert';
//import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:event/event.dart';
//testing:
import 'dart:io';


enum Priority{low, medium, high}
enum Progress{assigned, inProgress, completed}

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

  List<ToDo> get todos => _todos;
  List<ToDo> get completes => _completes;
  bool addTask(ToDo task)
  {
    if(_todos.contains(task))
      {
        return false;
      }
    _todos.add(task);
    // Subscribe to event.
    task.onComplete + (task) => completeTask;
    return true;
  }
  bool removeTask(ToDo task)
  {
    if(!_todos.remove(task))
    {
      return false;
    }
    // Unsubscribe to event.
    task.onComplete - (task) => completeTask;
    return true;
  }

    bool completeTask(ToDo task)
    {
      if(!removeTask(task))
      {
        return false;
      }
      _completes.add(task);
      return true;
    }
    // Lol.
    bool unCompleteTask(ToDo task)
    {
      if(!_completes.remove(task))
      {
        return false;
      }
      return addTask(task);
    }

    bool reOrderTask(ToDo task, int index)
    {
      if(!removeTask(task))
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



abstract class ToDo with DeadLine, EquatableMixin implements Comparable<ToDo> {
  String name;
  int weight;
  Priority priority;
  Progress _progress = Progress.assigned;
  // How the fuck do I use this thing.
  var onComplete = Event();

  ToDo({required this.name, this.weight = 0, this.priority = Priority.low, DateTime? startDate, DateTime? endDate})
  {
    this.startDate = startDate;
    this.endDate = endDate;
  }

  Progress get progress => _progress;
  set progress(Progress state)
  {
    _progress = state;
    if(state == Progress.completed)
      {
        onComplete.broadcast();
      }
  }

  @override
  int compareTo(ToDo t2) => name.compareTo(t2.name);

  @override
  List<Object> get props{
    return [name, weight, priority, _progress, startDate.toString(), endDate.toString()];
  }
}

class Task extends ToDo{
  Task({required super.name, super.weight, super.priority, super.startDate, super.endDate});

}
class LargeTask extends ToDo with DeadLine, TaskCollection {
  final maxSubTasks = 5;

  LargeTask({required super.name, super.weight, super.priority, super.startDate, super.endDate});

  @override
  set progress(Progress state)
  {
    if(state == Progress.completed && todos.isNotEmpty)
      {
        state = confirmFinished();
      }
    super.progress = state;
  }

  Progress confirmFinished()
  {
    //REMOVE => refactor into async method.
      print("Resolve all subtasks?");
      var input = stdin.readLineSync(encoding: utf8);
      if(input == 'y')
        {
          todos.forEach(completeTask);
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

    if(!addTask(task))
      {
        return false;
      }
    updateWeight();
    return true;
  }
  bool removeSubTask(Task task)
  {
    if(!removeTask(task))
      {
        return false;
      }
    updateWeight();
    return true;
  }
  bool completeSubTask(Task task)
  {
    if(!completeTask(task))
      {
        return false;
      }
    updateWeight();
    return true;
  }
  void updateWeight() => {weight = todos.fold(0, (p, c) => p + c.weight)};

  @override
  List<Object> get props => super.props..add(maxSubTasks);
}

class Reminder with DeadLine {
  String name;
  Reminder({required this.name, DateTime? startDate, DateTime? endDate})
  {
    this.startDate = startDate;
    this.endDate = endDate;
  }
}