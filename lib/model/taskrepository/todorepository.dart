import "../task/project.dart";
import "../task/reminder.dart";
import "../task/routine.dart";
import "../task/todocollection.dart";
import "../task/todo.dart";
class ToDoRepository with ToDoCollection<ToDo>
{
  // TODO: viewmodel > return a sorted view.
  final List<Reminder> reminders = [];
  final List<Routine> routines = [];
  final List<Project> projects = [];
  ToDoRepository();


  List<ToDo> get myDay => [...todos.where((t) => t.progress != Progress.completed && t.myDay == true)];

  // Reminders are always sorted by date.
  void addReminder(Reminder r) => reminders.add(r);
  void removeReminder(Reminder r) => reminders.remove(r);
  void addRoutine(Routine r) => routines.add(r);
  void removeRoutine(Routine r) => routines.remove(r);
  void addProject(Project p) => projects.add(p);
  void removeProject(Project p) => projects.remove(p);
}