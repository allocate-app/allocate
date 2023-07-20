import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../model/task/group.dart';
import '../model/user/user.dart';
import '../services/group_service.dart';
import '../services/todo_service.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/sorting/group_sorter.dart';

class GroupProvider extends ChangeNotifier {
  late Timer syncTimer;
  final GroupService _groupService;
  final ToDoService _toDoService;

  late Group curGroup;

  late List<Group> groups;

  List<Group> failCache = List.empty(growable: true);

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
      _reattemptUpdate();
      if (user!.syncOnline) {
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
      log("This is a fatal error.");
    } on FailureToUploadException catch (e) {
      log(e.cause);
      log("This is a fatal error, supabase issue");
    }
    notifyListeners();
  }

  Future<void> createGroup({required String name, String? description}) async {
    curGroup = Group(name: name, description: description ?? "");
    try {
      _groupService.createGroup(group: curGroup);
    } on FailureToCreateException catch (e) {
      log(e.cause);
      failCache.add(curGroup);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      failCache.add(curGroup);
      return;
    }

    notifyListeners();
  }

  Future<void> updateGroup({String? name, String? description}) async {
    Group group = curGroup.copyWith(name: name, description: description);
    group.id = curGroup.id;
    group.customViewIndex = curGroup.customViewIndex;
    curGroup = group;

    try {
      _groupService.updateGroup(group: curGroup);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      failCache.add(curGroup);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      failCache.add(curGroup);
    }
    notifyListeners();
  }

  Future<void> _reattemptUpdate() async {
    try {
      _groupService.updateBatch(groups: failCache);
      failCache.clear();
    } on FailureToUploadException catch (e) {
      log("DataCache - ${e.cause}");
    } on FailureToUpdateException catch (e) {
      log("DataCache - ${e.cause}");
    }
    notifyListeners();
  }

  Future<void> deleteGroup() async {
    try {
      _groupService.deleteGroup(group: curGroup);
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      failCache.add(curGroup);
    }
    notifyListeners();
  }

  Future<void> reorderGroups(
      {required List<Group> groups,
      required int oldIndex,
      required int newIndex}) async {
    try {
      _groupService.reorderGroups(
          groups: groups, oldIndex: oldIndex, newIndex: newIndex);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      failCache.addAll(groups);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      failCache.addAll(groups);
    }
    notifyListeners();
  }

  Future<void> reorderGroupToDos(
      {required int oldIndex, required int newIndex}) async {
    try {
      _toDoService.reorderGroupTasks(
          toDos: curGroup.toDos, oldIndex: oldIndex, newIndex: newIndex);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      failCache.add(curGroup);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      failCache.add(curGroup);
    }
  }

  Future<void> getGroupsBy() async {
    groups = await _groupService.getGroupsBy(sorter: sorter);
    for (Group g in groups) {
      g.toDos = await _toDoService.getByGroup(groupID: g.id);
    }
    notifyListeners();
  }
}
