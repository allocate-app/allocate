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
  bool rebuild = true;

  late Timer syncTimer;
  final GroupService _groupService;
  final ToDoService _toDoService;

  Group? curGroup;

  List<Group> groups = [];
  List<Group> secondaryGroups = [];

  final Map<int, String> groupNames = {
    Constants.intMax: "New Group",
  };
  final Map<int, ValueNotifier<int>> groupToDoCounts = {
    Constants.intMax: ValueNotifier<int>(0),
  };

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

  void setUser({User? newUser}) {
    user = newUser;
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
    Group? group = await getGroupByID(id: id);
    if (group == null) {
      return Future.error(
          GroupNotFoundException("Group $id: not found in storage"));
    }

    groupNames[id] = group.name;
    return group.name;
  }

  ValueNotifier<int>? getToDoCount({int? id}) {
    if (null == id) {
      return null;
    }
    if (groupToDoCounts.containsKey(id)) {
      return groupToDoCounts[id]!;
    }

    groupToDoCounts[id] = ValueNotifier<int>(0);
    setToDoCount(id: id);
    return groupToDoCounts[id]!;
  }

  Future<void> setToDoCount({required int id, int? count}) async {
    count = count ?? await _toDoService.getGroupToDoCount(groupID: id);
    if (groupToDoCounts.containsKey(id)) {
      groupToDoCounts[id]?.value = count;
    } else {
      groupToDoCounts[id] = ValueNotifier<int>(count);
    }
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

  Future<void> createGroup(
      {required String name, String? description, List<ToDo>? toDos}) async {
    // The likelihood of adding more than 50 tasks at creation is incredibly slim.
    toDos = toDos ?? await _toDoService.getByGroup(groupID: Constants.intMax);
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

    await _updateToDos(toDos: toDos, groupID: curGroup!.id);
    groupNames[curGroup!.id] = curGroup!.name;
    setToDoCount(id: Constants.intMax, count: 0);

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
    groupNames[curGroup!.id] = curGroup!.name;
  }

  Future<void> _updateToDos(
      {required List<ToDo> toDos, required int groupID}) async {
    int i = 0;
    for (ToDo toDo in toDos) {
      toDo.groupID = groupID;
      toDo.customViewIndex = i++;
    }
    try {
      await _toDoService.updateBatch(toDos: toDos);
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

    groupNames.remove(group.id);
    groupToDoCounts.remove(group.id);

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
          {int limit = Constants.minLimitPerQuery, int offset = 0}) async =>
      await _groupService.getGroups(limit: limit);

  Future<void> setGroups() async {
    groups = await _groupService.getGroups();
    for (Group g in groups) {
      g.toDos = await _toDoService.getByGroup(groupID: g.id);
    }
    notifyListeners();
  }

  Future<List<Group>> getGroupsBy({
    int limit = Constants.minLimitPerQuery,
    int offset = 0,
  }) async {
    List<Group> groups = await _groupService.getGroupsBy(
        sorter: sorter, limit: limit, offset: offset);

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

    return groups;
  }

  Future<void> setMostRecent() async =>
      secondaryGroups = await mostRecent(grabToDos: true);

  Future<Group?> getGroupByID({int? id}) async =>
      await _groupService.getGroupByID(id: id);

  Future<void> setGroupByID({required int id}) async =>
      await _groupService.getGroupByID(id: id) ??
      Group(name: '', lastUpdated: DateTime.now());
}
