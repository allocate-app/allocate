import 'dart:convert';
import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:event/event.dart';
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
  var sc = StreamController();

  List<ToDo> get todos => _todos;
  List<ToDo> get completes => _completes;
  bool _addTask(ToDo task)
  {
    if(_todos.contains(task))
      {
        return false;
      }
    task.onComplete + (t) => completeTask(t!.task);
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
      task.onComplete - (t) => completeTask(t!.task);
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



abstract class ToDo with DeadLine, EquatableMixin implements Comparable<ToDo> {
  String name;
  int weight;
  Priority priority;
  Progress _progress = Progress.assigned;
  var onComplete = Event<ToDoComplete>();

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
        onComplete.broadcast(ToDoComplete(this));
      }
  }

  @override
  int compareTo(ToDo t2) => name.compareTo(t2.name);

  @override
  List<Object> get props{
    return [name, weight, priority, progress, startDate.toString(), endDate.toString()];
  }
}

class ToDoComplete extends EventArgs
{
  ToDo task;
  ToDoComplete(this.task);
}


class Task extends ToDo{
  Task({required super.name, super.weight, super.priority, super.startDate, super.endDate});

}
class LargeTask extends ToDo with DeadLine, TaskCollection {
  final maxSubTasks = 5;
  LargeTask({required super.name, super.priority, super.startDate, super.endDate});

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
    updateWeight();
    return true;
  }
  bool removeSubTask(Task task)
  {
    if(!_removeTask(task))
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