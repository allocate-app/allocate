import 'package:flutter/foundation.dart';
import '../model/task/deadline.dart';
import '../model/task/repeat.dart';
import '../model/task/todo.dart';

abstract class ToDoViewModel extends ChangeNotifier
{
  // This is a mess. FIX.

  // ToDo _toDo;
  // ToDoViewModel({required ToDo toDo}) : _toDo = toDo;
  //
  // ToDo get todo => _toDo;
  // set todo(ToDo newToDo)
  // {
  //   _toDo = newToDo;
  //   notifyListeners();
  // }
  //
  // String get name => _toDo.name;
  // set name(String newName)
  // {
  //   _toDo.name = newName;
  //   notifyListeners();
  // }
  //
  // int get weight => _toDo.weight;
  // set weight(int newWeight)
  // {
  //   _toDo.weight = newWeight;
  //   notifyListeners();
  // }
  //
  // Duration get expectedDuration => _toDo.expectedDuration;
  // set expectedDuration(Duration newDuration)
  // {
  //   _toDo.expectedDuration = newDuration;
  //   notifyListeners();
  // }
  // Duration get realDuration => _toDo.realDuration;
  // Priority get priority => _toDo.priority;
  //
  // DeadLine get deadLine => _toDo.deadline;
  //
  // // TODO: MAY need to restructure using APIs.
  // set startDate(DateTime newStartDate)
  // {
  //   _toDo.deadline.startDate = newStartDate;
  //   notifyListeners();
  // }
  // set endDate(DateTime newEndDate)
  // {
  //   _toDo.deadline.dueDate = newEndDate;
  //   notifyListeners();
  // }
  //
  // set warnMe(bool warn)
  // {
  //   _toDo.deadline.warnMe = warn;
  //   notifyListeners();
  // }
  //
  // bool? get myDay => _toDo.myDay;
  // // UH.
  // set myDay(bool? toMyDay)
  // {
  //   _toDo.myDay = toMyDay;
  //   notifyListeners();
  // }
  //
  // Repeat get repeat => _toDo.repeat;




}