import 'dart:developer';

import 'package:flutter/foundation.dart';
import '../model/task/subtask.dart';
import '../model/task/todo.dart';
import '../services/todo_service.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/interfaces/datacache.dart';
import '../util/sorters/todo_sorter.dart';
import '../providers/todo_datacache.dart';

class ToDoProvider extends ChangeNotifier{
  ToDoProvider();
  // UI needs to have both a todo provider + group provider.

  //TODO: implement Todo service.
  final ToDoService _todoService = ToDoService.instance;

  //TODO: refactor Datacache into component.
  DataCache<ToDo> dataCache = ToDoDataCache.instance;

  ToDo get curToDo => dataCache.current;
  set curToDo(ToDo t) => dataCache.current = t;

  List<ToDo> get todos => dataCache.currents;
  set todos(List<ToDo> newTodos) => dataCache.currents = todos;

  List<ToDo> get failCache => dataCache.cache;

  ToDoSorter sorter = ToDoSorter();

  SortMethod get curSortMethod => sorter.sortMethod;
  set curSortMethod(SortMethod method)
  {
    if(method == sorter.sortMethod)
      {
        sorter.descending = !sorter.descending;
      }
    else
      {
        sorter.sortMethod = method;
        sorter.descending = false;
      }
    notifyListeners();
  }
  bool get descending => sorter.descending;
  List<SortMethod> get sortMethods => sorter.sortMethods;

  //TODO: refactor to take args.
  Future<void> createToDo(ToDo t) async {
    try
        {
          _todoService.createToDo(t);
        }
        on FailureToCreateException catch (e)
    {
      log(e.cause);
      failCache.add(t);

    }
    failCache.add(t);
  }
  Future<void> addSubTask(SubTask st) async
  {
    try
        {
          _todoService.addSubTask(st, curToDo);
        }
    on ListLimitExceededException catch (e)
    {
      log(e.cause);
    }
    notifyListeners();
  }

  Future<void> updateSubTask(int oldWeight, int newWeight) async
  {
    try{
      _todoService.updateSubTask(oldWeight, newWeight, curToDo);
    }
    on FailureToUpdateException catch (e)
    {
      log(e.cause);
      failCache.add(curToDo);
    }
    on FailureToUploadException catch (e)
    {
      log(e.cause);
      failCache.add(curToDo);
    }
    notifyListeners();
  }

  Future<void> deleteSubTask(SubTask st) async{
    try{
      _todoService.deleteSubTask(st, curToDo);
    }
    on FailureToUpdateException catch (e)
    {
      log(e.cause);
      failCache.add(curToDo);
    }
    on FailureToUploadException catch (e)
    {
      log(e.cause);
      failCache.add(curToDo);
    }

    notifyListeners();
  }

  Future<void> updateToDo(
      {TaskType? taskType,
        String? name,
        String? description,
        int? weight,
        Duration? expectedDuration,
        Priority? priority,
        DateTime? dueDate,
        bool? myDay,
        bool? repeatable,
        Frequency? frequency,
        List<bool>? repeatDays,
        int? repeatSkip,
        bool? isSynced,
        bool? toDelete,
        List<SubTask>? subTasks}) async {
    ToDo t = curToDo.copyWith(
      taskType: taskType,
      name: name,
      description: description,
      weight: weight,
      expectedDuration: expectedDuration,
      priority: priority,
      dueDate: dueDate,
      myDay: myDay,
      repeatable: repeatable,
      frequency: frequency,
      repeatDays: repeatDays,
      repeatSkip: repeatSkip,
      isSynced: isSynced,
      toDelete: toDelete,
      subTasks: subTasks,
    );
    t.id = curToDo.id;
    try
        {
          _todoService.updateToDo(t);
        }
      on FailureToUploadException catch (e)
    {
      log(e.cause);
      failCache.add(t);
    }
    on FailureToUpdateException catch (e)
    {
      log(e.cause);
      failCache.add(t);
    }
    notifyListeners();
  }

  Future<void> _updateBatch(List<ToDo> todos) async {
    try
        {
          _todoService.updateBatch(todos);
        } on FailureToUploadException catch (e)
    {
      log(e.cause);
      failCache.addAll(todos);
    }
    on FailureToUpdateException catch (e)
    {
      log(e.cause);
      failCache.addAll(todos);
    }
  }

  Future<void> _reattemptUpdate() async {
    try {
      _todoService.retry(failCache);
      failCache.clear();
    }
    on FailureToUploadException catch (e) {
      log("DataCache - ${e.cause}");
    }
    on FailureToUpdateException catch (e)
    {
      log("DataCache - ${e.cause}" );
    }
    notifyListeners();
  }

  Future<void> deleteTodo() async {
    try{
      _todoService.deleteToDo(curToDo);
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      failCache.add(curToDo);
    }
    notifyListeners();
  }

  Future<void> reorderToDos(int oldIndex, int newIndex) async {
    try {
      _todoService.reorderToDos(todos, oldIndex, newIndex);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      _updateBatch(todos);
    }
  }


  Future<void> getToDos() async{
    todos = await _todoService.getToDos();
    notifyListeners();
  }
  Future<void> getToDosBy() async {
    todos = await _todoService.getToDosBy(todoSorter: sorter);
    notifyListeners();
  }



}
