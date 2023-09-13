import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../model/task/group.dart';
import '../model/task/todo.dart';
import '../model/user/user.dart';
import '../services/group_service.dart';
import '../services/todo_service.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/sorting/group_sorter.dart';

class GroupProvider extends ChangeNotifier {
  bool rebuild = false;
  late Timer syncTimer;
  final GroupService _groupService;
  final ToDoService _toDoService;

  Group? curGroup;

  List<Group> groups = [];
  List<Group> recentGroups = [];

  late GroupSorter sorter;

  User? user;

  GroupProvider(
      {this.user, GroupService? groupService, ToDoService? toDoService})
      : _groupService = groupService ?? GroupService(),
        _toDoService = toDoService ?? ToDoService() {
    sorter = user?.groupSorter ?? GroupSorter();
    startTimer();
  }

  void startTimer() {
    syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (user?.syncOnline ?? false) {
        _syncRepo();
      } else {
        _groupService.clearDeletesLocalRepo();
      }
    });
  }

  void setUser({User? user}) {
    user = user;
    sorter = user?.groupSorter ?? sorter;
    notifyListeners();
  }

  SortMethod get sortMethod => sorter.sortMethod;

  set sortMethod(SortMethod method) {
    if (method == sorter.sortMethod) {
      sorter.descending = !sorter.descending;
    } else {
      sorter.sortMethod = method;
      sorter.descending = false;
    }
    user?.groupSorter = sorter;
    notifyListeners();
  }

  bool get descending => sorter.descending;

  List<SortMethod> get sortMethods => GroupSorter.sortMethods;

  Future<void> _syncRepo() async {
    // Not quite sure how to handle this outside of gui warning.
    try {
      _groupService.syncRepo();
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    notifyListeners();
  }

  Future<void> createGroup({required String name, String? description}) async {
    curGroup = Group(
        name: name,
        description: description ?? "",
        lastUpdated: DateTime.now());
    curGroup!.localID = curGroup.hashCode;
    try {
      _groupService.createGroup(group: curGroup!);
    } on FailureToCreateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      curGroup!.isSynced = false;
      return updateGroup();
    }
    notifyListeners();
  }

  Future<void> updateGroup() async {
    curGroup!.lastUpdated = DateTime.now();
    try {
      _groupService.updateGroup(group: curGroup!);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    notifyListeners();
  }

  Future<void> deleteGroup() async {
    try {
      _groupService.deleteGroup(group: curGroup!);
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    notifyListeners();
  }

  Future<List<ToDo>> getToDosByGroupId(
      {int? id, int limit = 50, int offset = 0}) async {
    return await _toDoService.getByGroup(
        groupID: id ?? curGroup?.localID, limit: limit, offset: offset);
  }

  Future<List<Group>> reorderGroups(
      {List<Group>? groups,
      required int oldIndex,
      required int newIndex}) async {
    try {
      return await _groupService.reorderGroups(
          groups: groups ?? this.groups,
          oldIndex: oldIndex,
          newIndex: newIndex);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<List<ToDo>> reorderGroupToDos(
      {required int oldIndex, required int newIndex, List<ToDo>? toDos}) async {
    try {
      return await _toDoService.reorderGroupToDos(
          toDos: toDos ?? curGroup!.toDos,
          oldIndex: oldIndex,
          newIndex: newIndex);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<List<Group>> getGroups(
          {required int limit, required int offset}) async =>
      await _groupService.getGroups(limit: limit);

  Future<void> setGroups() async {
    groups = await _groupService.getGroups();
    for (Group g in groups) {
      g.toDos = await _toDoService.getByGroup(groupID: g.id);
    }
    notifyListeners();
  }

  Future<List<Group>> getGroupsBy(
          {required int limit, required int offset}) async =>
      await _groupService.getGroupsBy(
          sorter: sorter, limit: limit, offset: offset);

  Future<void> setGroupsBy() async {
    groups =
        await _groupService.getGroupsBy(sorter: sorter, limit: 50, offset: 0);
    for (Group g in groups) {
      g.toDos = await _toDoService.getByGroup(groupID: g.id);
    }
    notifyListeners();
  }

  Future<List<Group>> searchGroups({required String searchString}) async =>
      _groupService.searchGroups(searchString: searchString);

  Future<List<Group>> mostRecent(
      {int limit = 5, bool grabToDos = false}) async {
    List<Group> groups = await _groupService.mostRecent(limit: 5);
    if (!grabToDos) {
      return groups;
    }

    for (Group group in groups) {
      group.toDos = await _toDoService.getByGroup();
    }
    return groups;
  }

  Future<void> setMostRecent() async =>
      recentGroups = await mostRecent(grabToDos: true);

  Future<Group?> getGroupByID({int? id}) async =>
      await _groupService.getGroupByID(id: id ?? curGroup?.id);

  Future<void> setGroupByID({required int id}) async =>
      await _groupService.getGroupByID(id: id) ??
      Group(name: '', lastUpdated: DateTime.now());
}
