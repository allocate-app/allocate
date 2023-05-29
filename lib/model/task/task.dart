import 'package:equatable/equatable.dart';
//import 'package:event/event.dart';

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

mixin TaskManager{
  final _todos = <ToDo>[];
  final _completes = <ToDo>[];

  List<ToDo> get todos => _todos;
  List<ToDo> get completes => _completes;
  void addTask(ToDo task) => {if(!_todos.contains(task)) _todos.add(task)};
  void removeTask(ToDo task) => {_todos.remove(task)};

  void completeTask(ToDo task)
  {
    removeTask(task);
    _completes.add(task);
  }

  void reOrderTask(ToDo task, int index)
  {
    removeTask(task);
    _todos.insert(index, task);
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
  Progress progress;

  ToDo({required this.name, this.weight = 0, this.priority = Priority.low, this.progress = Progress.assigned, DateTime? startDate, DateTime? endDate})
  {
    this.startDate = startDate;
    this.endDate = endDate;
  }


  @override
  int compareTo(ToDo t2) => name.compareTo(t2.name);

  @override
  List<Object> get props{
    return [name, weight, priority, progress, startDate.toString(), endDate.toString()];
  }
}

class Task extends ToDo{
  Task({required super.name, super.weight, super.priority, super.progress, super.startDate, super.endDate});

}
class LargeTask extends ToDo with DeadLine, TaskManager {
  // For now. Consider thinking about whether this should be calculated.
  static const maxSubTasks = 5;
  // NEED TO OVERRIDE PROGRESS SETTER -> WHEN SUBTASKS AREN'T DONE.
  LargeTask({required super.name, super.weight, super.priority, super.progress, super.startDate, super.endDate});

  void addSubTask(Task task)
  {
    if(todos.length > maxSubTasks)
      {
        // TODO: Handle this properly.
        throw Error();
      }

    addTask(task);
    updateWeight();
  }
  void removeSubTask(Task task)
  {
    removeTask(task);
    updateWeight();
  }
  void completeSubTask(Task task)
  {
    completeTask(task);
    updateWeight();
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