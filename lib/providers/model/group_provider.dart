import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../../model/task/group.dart';
import '../../model/task/todo.dart';
import '../../repositories/group_repo.dart';
import '../../repositories/todo_repo.dart';
import '../../util/constants.dart';
import '../../util/enums.dart';
import '../../util/exceptions.dart';
import '../../util/interfaces/repository/model/group_repository.dart';
import '../../util/interfaces/repository/model/todo_repository.dart';
import '../../util/sorting/group_sorter.dart';
import '../viewmodels/user_viewmodel.dart';

class GroupProvider extends ChangeNotifier {
  bool _rebuild = true;

  bool get rebuild => _rebuild;

  // Secondary groups update separately
  // According to the main gui
  set rebuild(bool rebuild) {
    _rebuild = rebuild;
    if (_rebuild) {
      groups = [];
      notifyListeners();
    }
  }

  set softRebuild(bool rebuild) {
    _rebuild = rebuild;
    if (_rebuild) {
      groups = [];
    }
  }

  late final GroupRepository _groupRepo;
  late final ToDoRepository _toDoRepo;

  Group? curGroup;

  List<Group> groups = [];

  // For nav bar groups
  late ValueNotifier<int> navKey;
  List<Group> secondaryGroups = [];

  final Map<int, String> groupNames = {};
  final Map<int, ValueNotifier<int>> groupToDoCounts = {};

  late GroupSorter sorter;

  UserViewModel? userViewModel;

  // CONSTRUCTOR
  GroupProvider({
    this.userViewModel,
    GroupRepository? groupRepository,
    ToDoRepository? toDoRepository,
  })  : sorter = userViewModel?.groupSorter ?? GroupSorter(),
        _groupRepo = groupRepository ?? GroupRepo.instance,
        _toDoRepo = toDoRepository ?? ToDoRepo.instance,
        navKey = ValueNotifier<int>(0) {
    _groupRepo.addListener(notifyListeners);
  }

  Future<void> init() async {
    await _groupRepo.init();
    notifyListeners();
  }

  void setUser({UserViewModel? newUser}) {
    userViewModel = newUser;
    if (userViewModel?.groupSorter == sorter) {
      return;
    }
    sorter = userViewModel?.groupSorter ?? sorter;
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
    userViewModel?.groupSorter = sorter;
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
    count = count ?? await _toDoRepo.getGroupToDoCount(groupID: id);
    if (groupToDoCounts.containsKey(id)) {
      groupToDoCounts[id]?.value = count;
    } else {
      groupToDoCounts[id] = ValueNotifier<int>(count);
    }
  }

  Future<void> refreshRepo() async {
    try {
      await _groupRepo.refreshRepo();
      notifyListeners();
    } on FailureToDeleteException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on FailureToUploadException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> syncRepo() async {
    try {
      await _groupRepo.syncRepo();
      notifyListeners();
    } on FailureToDeleteException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on FailureToUploadException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> createGroup(Group group) async {
    try {
      // Check for db collisions.
      bool inDB = await _groupRepo.containsID(id: group.id);

      while (inDB) {
        group.id = group.id + 1;
        inDB = await _groupRepo.containsID(id: group.id);
      }

      curGroup = await _groupRepo.create(group);

      // This should bake the index
      for (int i = 0; i < group.toDos.length; i++) {
        group.toDos[i].groupIndex = i;
      }
      await _toDoRepo.updateBatch(group.toDos);

      notifyListeners();
    } on FailureToCreateException catch (e) {
      log(e.cause);
      notifyListeners();
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      group.isSynced = false;
      notifyListeners();
      return await updateGroup(group: group);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }

    groupNames[curGroup!.id] = curGroup!.name;
  }

  Future<void> updateGroup({Group? group}) async {
    await updateGroupAsync(group: group);
    notifyListeners();
  }

  Future<void> updateGroupAsync({Group? group}) async {
    group = group ?? curGroup;

    if (null == group) {
      throw FailureToUpdateException("Invalid model provided");
    }
    try {
      curGroup = await _groupRepo.update(group);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
    groupNames[curGroup!.id] = curGroup!.name;
  }

  // Future<void> _updateToDos(
  //     {required List<ToDo> toDos, required int groupID}) async {
  //   int i = 0;
  //   for (ToDo toDo in toDos) {
  //     toDo.groupID = groupID;
  //     toDo.customViewIndex = i++;
  //   }
  //   try {
  //     await _toDoRepo.updateBatch(toDos);
  //   } on FailureToUploadException catch (e) {
  //     log(e.cause);
  //     return Future.error(e);
  //   } on FailureToUpdateException catch (e) {
  //     log(e.cause);
  //     return Future.error(e);
  //   } on Error catch (e, stacktrace) {
  //     log("Unknown error", stackTrace: stacktrace);
  //     return Future.error(UnexpectedErrorException(), stacktrace);
  //   }
  // }

  Future<void> deleteGroup({Group? group}) async {
    group = group ?? curGroup!;
    try {
      await _groupRepo.delete(group);
      groupNames.remove(group.id);
      groupToDoCounts.remove(group.id);
      notifyListeners();
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      notifyListeners();
      return Future.error(e);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> removeGroup({Group? group}) async {
    if (null == group) {
      return;
    }
    try {
      await _groupRepo.remove(group);
      notifyListeners();
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      notifyListeners();
      return Future.error(e);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> restoreGroup({Group? group}) async {
    if (null == group) {
      return;
    }
    group.toDelete = false;
    try {
      curGroup = await _groupRepo.update(group);
      notifyListeners();
    } on FailureToUploadException catch (e) {
      log(e.cause);
      notifyListeners();
      return Future.error(e);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      notifyListeners();
      return Future.error(e);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> emptyTrash() async {
    try {
      List<int> ids = await _groupRepo.emptyTrash();
      for (int id in ids) {
        List<ToDo> toDos = await _toDoRepo.getRepoByGroupID(
            groupID: id, limit: Constants.maxLimitPerQuery, offset: 0);
        for (ToDo toDo in toDos) {
          toDo.groupID = null;
        }
        await _toDoRepo.updateBatch(toDos);

        groupNames.remove(id);
        groupToDoCounts.remove(id);
      }
      notifyListeners();
    } on FailureToDeleteException catch (e) {
      log(e.cause);
      notifyListeners();
      return Future.error(e);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> dayReset() async {
    DateTime? upTo = userViewModel?.deleteDate;
    if (null != upTo) {
      try {
        await _groupRepo.deleteSweep(upTo: upTo);
      } on FailureToDeleteException catch (e, stacktrace) {
        log(e.cause, stackTrace: stacktrace);
        return Future.error(e, stacktrace);
      } on Error catch (e, stacktrace) {
        log("Unknown error", stackTrace: stacktrace);
        return Future.error(UnexpectedErrorException(), stacktrace);
      }
    }
  }

  Future<void> clearDatabase() async {
    curGroup = null;
    groups = [];
    secondaryGroups = [];
    _rebuild = true;
    groupNames.clear();
    groupToDoCounts.clear();
    await _groupRepo.clearDB();
  }

  Future<List<ToDo>> getToDosByGroupID(
      {int? id, int limit = 50, int offset = 0}) async {
    return await _toDoRepo.getRepoByGroupID(
        groupID: id ?? curGroup!.id, limit: limit, offset: offset);
  }

  Future<List<Group>> reorderGroups(
      {List<Group>? groups,
      required int oldIndex,
      required int newIndex}) async {
    groups = groups ?? this.groups;
    // NOTE: Index correction is in the custom separated
    // reorderable listview.
    // if (oldIndex < newIndex) {
    //   newIndex--;
    // }
    Group group = groups.removeAt(oldIndex);
    groups.insert(newIndex, group);
    for (int i = 0; i < groups.length; i++) {
      groups[i].customViewIndex = i;
    }
    try {
      await _groupRepo.updateBatch(groups);
      return groups;
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<List<ToDo>> reorderGroupToDos(
      {required int oldIndex, required int newIndex, List<ToDo>? toDos}) async {
    toDos = toDos ?? curGroup!.toDos;

    if (oldIndex < newIndex) {
      newIndex--;
    }
    ToDo toDo = toDos.removeAt(oldIndex);
    toDos.insert(newIndex, toDo);
    for (int i = 0; i < toDos.length; i++) {
      toDos[i].customViewIndex = i;
    }
    try {
      await _toDoRepo.updateBatch(toDos);
      return toDos;
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<List<Group>> getGroups(
          {int limit = Constants.minLimitPerQuery, int offset = 0}) async =>
      await _groupRepo.getRepoList(limit: limit, offset: offset);

  // Future<void> setGroups() async {
  //   groups = await _groupService.getGroups();
  //   for (Group g in groups) {
  //     g.toDos = await _toDoService.getByGroup(groupID: g.id);
  //   }
  //   notifyListeners();
  // }

  Future<List<Group>> getGroupsBy({
    int limit = Constants.minLimitPerQuery,
    int offset = 0,
  }) async {
    List<Group> groups = await _groupRepo.getRepoListBy(
        sorter: sorter, limit: limit, offset: offset);

    return groups;
  }

  // Future<void> setGroupsBy() async {
  //   groups =
  //       await _groupService.getGroupsBy(sorter: sorter, limit: 50, offset: 0);
  //   for (Group group in groups) {
  //     group.toDos = await _toDoService.getByGroup(groupID: group.id);
  //   }
  //   notifyListeners();
  // }

  Future<List<Group>> searchGroups(
          {required String searchString, bool toDelete = false}) async =>
      await _groupRepo.search(searchString: searchString, toDelete: toDelete);

  Future<List<Group>> mostRecent({int limit = 5}) async {
    List<Group> groups = await _groupRepo.mostRecent(limit: 5);

    return groups;
  }

  Future<void> setMostRecent() async => secondaryGroups = await mostRecent();

  Future<Group?> getGroupByID({int? id}) async {
    if (null == id) {
      return null;
    }
    return await _groupRepo.getByID(id: id);
  }

  Future<List<Group>> getDeleted(
          {int limit = Constants.minLimitPerQuery, int offset = 0}) async =>
      await _groupRepo.getDeleted(limit: limit, offset: offset);

// Future<void> setGroupByID({required int id}) async =>
//     await _groupService.getGroupByID(id: id) ??
//     Group(name: '', lastUpdated: DateTime.now());
}
