import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../model/task/group.dart';
import '../services/group_service.dart';
import '../services/todo_service.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/interfaces/sorting/group_sorter.dart';

class GroupProvider extends ChangeNotifier {
  GroupProvider();

  final GroupService _groupService = GroupService();
  final ToDoService _toDoService = ToDoService();

  late Group curGroup;

  late List<Group> groups;

  List<Group> failCache = List.empty(growable: true);

  GroupSorter sorter = GroupSorter();

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

  // Future<void> _updateBatch({required List<Group> groups}) async {
  //   try {
  //     _groupService.updateBatch(groups: groups);
  //   } on FailureToUploadException catch (e) {
  //     log(e.cause);
  //     failCache.addAll(groups);
  //   } on FailureToUpdateException catch (e) {
  //     log(e.cause);
  //     failCache.addAll(groups);
  //   }
  // }

  Future<void> _reattemptUpdate() async {
    try {
      _groupService.retry(groups: failCache);
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
