// TODO: Implement this.
import "dart:collection";
import "package:flutter/foundation.dart";
import "../model/task/todo.dart";
import "../model/task/task.dart";
import "../model/task/largetask.dart";
import "../model/task/routine.dart";
import "../model/task/reminder.dart";
import "../model/task/todocollection.dart";
import "../model/task/group.dart";
import "../model/taskrepository/repositoryprefs.dart";
import "../model/taskrepository/todorepository.dart";
import "../user/user.dart";
class ToDoRepositoryViewModel extends ChangeNotifier
{
  final ToDoRepository _repository;
  // FIGURE OUT HOW TO SET THE REPOSITORY && user ASYNC.
  final User _user;
  final RepositoryPrefs _repoPrefs;

  ToDoRepositoryViewModel({required ToDoRepository repository, required User user, required RepositoryPrefs repoPrefs}) : _user = user, _repository = repository, _repoPrefs = repoPrefs;
  // I thiink this is wise to have separate pointers.
  // Set these on selecting a gui frame thingy.
  LargeTask? curLt;
  Project? curProj;
  Task? curTask;
  Routine? curRoutine;
  Reminder? curReminder;

  // CALLBACK LISTS > These may not actually get used. It might be better to call it all through the sorter.
  UnmodifiableListView<ToDo> get complete => UnmodifiableListView(_repository.sorted(list: _repository.complete, sortBy: _repoPrefs.curSort, reverse: _repoPrefs.revSort));
  UnmodifiableListView<ToDo> get unComplete => UnmodifiableListView(_repository.sorted(list: _repository.unComplete, sortBy: _repoPrefs.curSort, reverse: _repoPrefs.revSort));
  UnmodifiableListView<ToDo> get projects => UnmodifiableListView(_repository.sorted(list: _repository.projects, sortBy: _repoPrefs.curSort, reverse: _repoPrefs.revSort));
  //My Day
  UnmodifiableListView<ToDo> get myDay => UnmodifiableListView(_repository.sorted(list: _repository.myDay, sortBy: _repoPrefs.curSort, reverse: _repoPrefs.revSort));

  // Reminders
  UnmodifiableListView<Reminder> get reminders
  {
    List<Reminder> reminders = _repository.reminders;
    reminders.sort();
    return UnmodifiableListView(reminders);
  }
  // Routines
  UnmodifiableListView<Routine> get routine => UnmodifiableListView(_repository.sorted(list: _repository.routines, sortBy: _repoPrefs.curSort, reverse: _repoPrefs.revSort) as List<Routine>);

  // Sort callback just in-case
  UnmodifiableListView<ToDo> sort(List<ToDo>? list) => UnmodifiableListView(_repository.sorted(list: list, sortBy: _repoPrefs.curSort, reverse: _repoPrefs.revSort));

  // Repo prefs
  SortMethod get curSort => _repoPrefs.curSort;
  set curSort(SortMethod newSort) {
    _repoPrefs.curSort = newSort;
    notifyListeners();
  }
  bool get revSort => _repoPrefs.revSort;
  set revSort(bool reverse) {
    _repoPrefs.revSort = reverse;
    notifyListeners();
  }

  void addToMyDay()
  {
    if(curTask!.weight > _user.dayBandwidth)
      {
        throw Error();
      }
    curTask!.myDay = true;
    notifyListeners();
  }
  void removeFromMyDay(ToDo t)
  {
    t.myDay = false;
    notifyListeners();
  }

  void addToDo(ToDo t)
  {
    _repository.add(t);
    notifyListeners();
  }
  void removeToDo(ToDo t)
  {
    _repository.remove(t);
    notifyListeners();
  }

  void editToDo(ToDo t)
  {
    //TODO: GET/POST;
    notifyListeners();
  }

  // This will reorder everything that inherits from todo.
  void reorderToDo(ToDo t1, ToDo t2, List<ToDo> list)
  {
    // This automatically reverts the view to custom.

    // Switch based on what is being viewed/modified.
    _repository.reorder(t1, t2, list: list);
    notifyListeners();
  }

  void removeCompletes()
  {
    _repository.removeAllCompletes();
    notifyListeners();
  }

  // Routine stuff.
  void createRoutine(Routine r)
  {
    // TODO: GET/POST
    _repository.addRoutine(r);
    notifyListeners();
  }

  void removeRoutine(Routine r)
  {
    // TODO: GET/POST
    _repository.removeRoutine(r);
    notifyListeners();
  }
  // Reminder stuff.
  void createReminder(Reminder r)
  {
    // curReminder = Reminder(GET/POST);
    // TODO: FIGURE OUT HOW TO GET/POST DATA FROM GUI
    _repository.addReminder(r);
    notifyListeners();
  }
  // This may not need to be its own method.
  // This needs its own vm.
  void editReminder()
  {
    // TODO: GET/POST;
    notifyListeners();
  }

  void removeReminder(Reminder r)
  {
    // TODO: GET/POST
    // should use curReminder;
    _repository.removeReminder(r);
    // curReminder = null;
    notifyListeners();
  }
  // Chron stuff: Should set a scheduler to auto-delete things?
  // Maybe do it via space left?


}
