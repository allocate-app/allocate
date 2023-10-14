import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../model/task/group.dart';
import '../model/task/todo.dart';
import '../model/user/user.dart';
import '../services/group_service.dart';
import '../services/todo_service.dart';
import '../util/constants.dart';
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

  final Map<int, String> groupNames = {};

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

  List<SortMethod> get sortMethods => sorter.sortMethods;

  Future<String> getGroupName({required int id}) async {
    if (id == Constants.initialGroupID) {
      return "New Group";
    }
    if (groupNames.containsKey(id)) {
      return groupNames[id]!;
    }

    Group? group = await getGroupByID(id: id);
    if (group == null) {
      return Future.error(
          GroupNotFoundException("Group $id: not found in storage"));
    }

    groupNames[id] = group.name;
    return group.name;
  }

  Future<void> _syncRepo() async {
    // Not quite sure how to handle this outside of gui warning.
    try {
      await _groupService.syncRepo();
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
    try {
      curGroup = await _groupService.createGroup(group: curGroup!);
    } on FailureToCreateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      curGroup!.isSynced = false;
      return await updateGroup();
    }
    notifyListeners();
  }

  Future<void> updateGroup({Group? group}) async {
    await updateGroupAsync(group: group);
    notifyListeners();
  }

  Future<void> updateGroupAsync({Group? group}) async {
    group = group ?? curGroup!;
    group.lastUpdated = DateTime.now();
    try {
      curGroup = await _groupService.updateGroup(group: group);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<void> deleteGroup({Group? group}) async {
    group = group ?? curGroup!;
    try {
      await _groupService.deleteGroup(group: group);
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    if (group == curGroup) {
      curGroup = null;
    }
    notifyListeners();
  }

  Future<List<ToDo>> getToDosByGroupID(
      {int? id, int limit = 50, int offset = 0}) async {
    return await _toDoService.getByGroup(
        groupID: id ?? curGroup!.id, limit: limit, offset: offset);
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
      {required int limit, required int offset, bool grabToDos = false}) async {
    List<Group> groups = await _groupService.getGroupsBy(
        sorter: sorter, limit: limit, offset: offset);
    if (grabToDos) {
      for (Group group in groups) {
        group.toDos = await _toDoService.getByGroup(groupID: group.id);
      }
    }

    return groups;
  }

  Future<void> setGroupsBy() async {
    groups =
        await _groupService.getGroupsBy(sorter: sorter, limit: 50, offset: 0);
    for (Group group in groups) {
      group.toDos = await _toDoService.getByGroup(groupID: group.id);
    }
    notifyListeners();
  }

  Future<List<Group>> searchGroups({required String searchString}) async =>
      await _groupService.searchGroups(searchString: searchString);

  Future<List<Group>> mostRecent(
      {int limit = 5, bool grabToDos = false}) async {
    List<Group> groups = await _groupService.mostRecent(limit: 5);
    if (grabToDos) {
      for (Group group in groups) {
        group.toDos = await _toDoService.getByGroup(groupID: group.id);
      }
    }

    return groups;
  }

  Future<void> setMostRecent() async =>
      recentGroups = await mostRecent(grabToDos: true);

  Future<Group?> getGroupByID({int? id}) async =>
      await _groupService.getGroupByID(id: id);

  Future<void> setGroupByID({required int id}) async =>
      await _groupService.getGroupByID(id: id) ??
      Group(name: '', lastUpdated: DateTime.now());
}
