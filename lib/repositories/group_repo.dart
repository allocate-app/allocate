import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/task/group.dart';
import '../model/task/todo.dart';
import '../services/isar_service.dart';
import '../services/supabase_service.dart';
import '../util/constants.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/interfaces/repository/model/group_repository.dart';
import '../util/interfaces/sortable.dart';

class GroupRepo extends ChangeNotifier implements GroupRepository {
  static final GroupRepo _instance = GroupRepo._internal();

  static GroupRepo get instance => _instance;

  late final SupabaseClient _supabaseClient;
  late final RealtimeChannel _groupStream;

  late final Isar _isarClient;

  bool get isConnected =>
      SupabaseService.instance.isConnected &&
      IsarService.instance.dbSize.value < Constants.supabaseLimit;

  bool get dbFull => IsarService.instance.dbSize.value >= Constants.isarLimit;

  int _groupCount = 0;
  bool _subscribed = false;
  bool _initialized = false;

  String get uuid => _supabaseClient.auth.currentUser?.id ?? "";
  String? currentUserID;

  @override
  void init() {
    if (_initialized) {
      return;
    }
    _isarClient = IsarService.instance.isarClient;
    _supabaseClient = SupabaseService.instance.supabaseClient;
    _initialized = true;
    // I haven't faked the connection channels -> doesn't make sense to.
    if (SupabaseService.instance.offlineDebug) {
      return;
    }
    // Initialize table stream -> only listen on signIn.
    _groupStream = _supabaseClient
        .channel("public:groups")
        .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: "public",
            table: "groups",
            callback: handleUpsert)
        .onPostgresChanges(
            schema: "public",
            table: "groups",
            event: PostgresChangeEvent.update,
            callback: handleUpsert)
        .onPostgresChanges(
            schema: "public",
            table: "groups",
            event: PostgresChangeEvent.delete,
            callback: handleDelete);

    // Listen to auth changes.
    SupabaseService.instance.authSubscription.listen((AuthState data) async {
      final AuthChangeEvent event = data.event;
      switch (event) {
        case AuthChangeEvent.initialSession:
          await handleUserChange();
          // OPEN TABLE STREAM -> insert new data.
          if (!_subscribed) {
            _groupStream.subscribe();
            _subscribed = true;
          }
        case AuthChangeEvent.signedIn:
          await handleUserChange();
          // This should close and re-open the subscription?
          if (!_subscribed) {
            _groupStream.subscribe();
            _subscribed = true;
          }
          break;
        case AuthChangeEvent.tokenRefreshed:
          if (!_subscribed) {
            await handleUserChange();
            _groupStream.subscribe();
            _subscribed = true;
          }
          break;
        case AuthChangeEvent.signedOut:
          // await _groupStream.unsubscribe();
          // _subscribed = false;
          break;
        default:
          break;
      }
    });

    // This is for online stuff.
    SupabaseService.instance.connectionSubscription
        .listen((ConnectivityResult result) async {
      if (result == ConnectivityResult.none) {
        return;
      }

      // This is to give enough time for the internet to check.
      await Future.delayed(const Duration(seconds: 2));
      if (!isConnected) {
        return;
      }
      await handleUserChange();
    });

    // This is for watching db size.
    _isarClient.groups.watchLazy().listen((_) async {
      await IsarService.instance.updateDBSize();
    });
    handleUserChange();
  }

  Future<void> handleUserChange() async {
    String? newID = _supabaseClient.auth.currentUser?.id;

    if (newID == currentUserID) {
      return syncRepo();
    }

    // In the case that the previous currentUserID was null.
    // This implies a new login, or a fresh open.
    // if not online, this will just early return.
    if (null == currentUserID) {
      currentUserID = newID;
      return await syncRepo();
    }

    // This implies there is a new user -> clear the DB
    // and insert the new user.
    currentUserID = newID;
    return await swapRepo();
  }

  @override
  Future<Group> create(Group group) async {
    if (dbFull) {
      throw LocalLimitExceededException(
          "Database is full. Size: ${IsarService.instance.dbSize.value / 1000000}");
    }
    group.isSynced = isConnected;
    late int? id;

    await _isarClient.writeTxn(() async {
      id = await _isarClient.groups.put(group);
    });

    if (null == id) {
      throw FailureToCreateException("Failed to create group locally\n"
          "Group: ${group.toString()}\n"
          "Time: ${DateTime.now()}\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (isConnected) {
      Map<String, dynamic> groupEntity = group.toEntity();
      groupEntity["uuid"] = uuid;
      final List<Map<String, dynamic>> response =
          await _supabaseClient.from("groups").insert(groupEntity).select("id");
      id = response.last["id"];
      if (null == id) {
        throw FailureToUploadException("Failed to sync group on create");
      }
    }
    return group;
  }

  @override
  Future<Group> update(Group group) async {
    group.isSynced = isConnected;

    late int? id;
    await _isarClient.writeTxn(() async {
      id = await _isarClient.groups.put(group);
    });

    if (null == id) {
      throw FailureToUpdateException("Failed to update group locally\n"
          "Group: ${group.toString()}\n"
          "Time: ${DateTime.now()}\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (isConnected) {
      Map<String, dynamic> groupEntity = group.toEntity();
      groupEntity["uuid"] = uuid;
      final List<Map<String, dynamic>> response =
          await _supabaseClient.from("groups").upsert(groupEntity).select("id");

      id = response.last["id"];

      if (null == id) {
        throw FailureToUploadException("Failed to sync group on update\n"
            "Group: ${group.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
    return group;
  }

  @override
  Future<void> updateBatch(List<Group> groups) async {
    late List<int?> ids;
    late int? id;
    await _isarClient.writeTxn(() async {
      ids = List<int?>.empty(growable: true);
      for (Group group in groups) {
        group.isSynced = isConnected;
        id = await _isarClient.groups.put(group);
        ids.add(id);
      }
    });
    if (ids.any((id) => null == id)) {
      throw FailureToUpdateException("Failed to update groups locally\n"
          "Groups: ${groups.toString()}\n"
          "Time: ${DateTime.now()}\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (isConnected) {
      ids.clear();
      List<Map<String, dynamic>> groupEntities = groups.map((group) {
        Map<String, dynamic> entity = group.toEntity();
        entity["uuid"] = uuid;
        return entity;
      }).toList();
      for (Map<String, dynamic> groupEntity in groupEntities) {
        final List<Map<String, dynamic>> response = await _supabaseClient
            .from("groups")
            .update(groupEntity)
            .select("id");
        id = response.last["id"];
        ids.add(id);
      }
      if (ids.any((id) => null == id)) {
        throw FailureToUploadException("Failed to sync groups on update\n"
            "Groups: ${groups.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
  }

  @override
  Future<void> delete(Group group) async {
    group.toDelete = true;
    await update(group);
  }

  @override
  Future<void> remove(Group group) async {
    // Delete online
    if (isConnected) {
      try {
        await _supabaseClient.from("groups").delete().eq("id", group.id);
      } catch (error) {
        throw FailureToDeleteException("Failed to delete Group online\n"
            "Group: ${group.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
    // Delete local
    await _isarClient.writeTxn(() async {
      await _isarClient.groups.delete(group.id);
    });
  }

  @override
  Future<List<int>> emptyTrash() async {
    if (isConnected) {
      try {
        await _supabaseClient.from("groups").delete().eq("toDelete", true);
      } catch (error) {
        throw FailureToDeleteException("Failed to empty trash online\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
    late List<int> deleteIDs;
    await _isarClient.writeTxn(() async {
      deleteIDs = await _isarClient.groups
          .where()
          .toDeleteEqualTo(true)
          .idProperty()
          .findAll();
      await _isarClient.groups.deleteAll(deleteIDs);
    });
    return deleteIDs;
  }

  @override
  Future<void> clearDB() async {
    if (isConnected) {
      // not sure whether or not to catch errors.
      await _supabaseClient.from("groups").delete().neq("customViewIndex", -2);
    }

    await _isarClient.writeTxn(() async {
      await _isarClient.groups.clear();
    });
  }

  Future<void> clearLocal() async {
    await _isarClient.writeTxn(() async {
      await _isarClient.groups.clear();
    });
  }

  @override
  Future<void> deleteSweep({DateTime? upTo}) async {
    List<int> toDeletes = await getDeleteIDs(deleteLimit: upTo);
    // For local update
    List<ToDo> toDos = List.empty(growable: true);
    // For online update
    List<Map<String, dynamic>> entities = List.empty(growable: true);
    for (int id in toDeletes) {
      List<ToDo> groupToDos =
          await _isarClient.toDos.where().groupIDEqualTo(id).findAll();
      for (ToDo toDo in groupToDos) {
        toDo.groupID = null;
        toDo.groupIndex = -1;
        toDos.add(toDo);
        Map<String, dynamic> entity = toDo.toEntity();
        entity["uuid"] = uuid;
        entities.add(entity);
      }
    }

    if (isConnected) {
      try {
        await _supabaseClient.from("groups").delete().inFilter("id", toDeletes);
        await _supabaseClient.from("toDos").upsert(entities);
      } catch (error) {
        throw FailureToDeleteException("Failed to delete groups online \n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
    await _isarClient.writeTxn(() async {
      await _isarClient.groups.deleteAll(toDeletes);
      for (ToDo toDo in toDos) {
        await _isarClient.toDos.put(toDo);
      }
    });
  }

  Future<int> getOnlineCount() async =>
      _supabaseClient.from("groups").count(CountOption.exact);

  @override
  Future<void> syncRepo() async {
    if (!isConnected) {
      return;
    }

    // Get the set of unsynced data.
    Set<Group> unsynced = await getUnsynced().then((_) => _.toSet());

    // Get the online count.
    _groupCount = await getOnlineCount();

    // Fetch new data -> by fetchRepo();
    List<Group> onlineGroups = await fetchRepo();

    List<Group> toInsert = List.empty(growable: true);
    for (Group group in onlineGroups) {
      Group? otherGroup = unsynced.lookup(group);
      // Prioritize by last updated -> unsynced data will overwrite new data.
      if (null != otherGroup &&
          group.lastUpdated.isAfter(otherGroup.lastUpdated)) {
        unsynced.remove(otherGroup);
      }
      toInsert.add(group);
    }

    // Put all new data in the db.
    await _isarClient.writeTxn(() async {
      await _isarClient.groups.putAll(toInsert);
    });

    // Update the unsynced data.
    await updateBatch(unsynced.toList());

    if (onlineGroups.length < _groupCount) {
      // Give the db a moment to refresh.
      await Future.delayed(const Duration(seconds: 1));
      insertRemaining(totalFetched: onlineGroups.length).whenComplete(() {
        notifyListeners();
      });
    }

    notifyListeners();
  }

  Future<void> insertRemaining({required int totalFetched}) async {
    List<Group> toInsert = List.empty(growable: true);
    while (totalFetched < _groupCount) {
      List<Group>? newGroups = await fetchRepo(offset: totalFetched);

      // If there is no data or connection is lost, break.
      if (newGroups.isEmpty) {
        break;
      }
      toInsert.addAll(newGroups);
      totalFetched += newGroups.length;
    }

    await _isarClient.writeTxn(() async {
      await _isarClient.groups.putAll(toInsert);
    });
  }

  @override
  Future<List<Group>> fetchRepo({int limit = 1000, int offset = 0}) async {
    List<Group> data = List.empty(growable: true);
    if (!isConnected) {
      return data;
    }
    try {
      List<Map<String, dynamic>> groupEntities = await _supabaseClient
          .from("groups")
          .select()
          .eq("uuid", uuid)
          .order("lastUpdated", ascending: false)
          .range(offset, offset + limit);

      for (Map<String, dynamic> entity in groupEntities) {
        data.add(Group.fromEntity(entity: entity));
      }
    } on Error catch (e, stacktrace) {
      log(e.toString(), stackTrace: stacktrace);
    }
    return data;
  }

  Future<void> swapRepo() async {
    await clearLocal();
    await syncRepo();
  }

  Future<void> handleUpsert(PostgresChangePayload payload) async {
    Group group = Group.fromEntity(entity: payload.newRecord);
    await _isarClient.writeTxn(() async {
      await _isarClient.groups.put(group);
    });

    _groupCount = await getOnlineCount();
    notifyListeners();
  }

  Future<void> handleDelete(PostgresChangePayload payload) async {
    int deleteID = payload.oldRecord["id"] as int;
    await _isarClient.writeTxn(() async {
      await _isarClient.groups.delete(deleteID);
    });

    _groupCount = await getOnlineCount();
    notifyListeners();
  }

  @override
  Future<List<Group>> search(
          {required String searchString, bool toDelete = false}) async =>
      await _isarClient.groups
          .where()
          .toDeleteEqualTo(toDelete)
          .filter()
          .nameContains(searchString, caseSensitive: false)
          .limit(5)
          .findAll();

  @override
  Future<List<Group>> mostRecent({int limit = 50}) async =>
      await _isarClient.groups
          .where()
          .toDeleteEqualTo(false)
          .sortByLastUpdatedDesc()
          .limit(limit)
          .findAll();

  @override
  Future<Group?> getByID({required int id}) async => await _isarClient.groups
      .where()
      .idEqualTo(id)
      .filter()
      .toDeleteEqualTo(false)
      .findFirst();

  // Basic query logic.
  @override
  Future<List<Group>> getRepoList({int limit = 50, int offset = 0}) async =>
      await _isarClient.groups
          .where()
          .toDeleteEqualTo(false)
          .sortByCustomViewIndex()
          .thenByLastUpdatedDesc()
          .offset(offset)
          .limit(limit)
          .findAll();

  @override
  Future<List<Group>> getRepoListBy(
      {required SortableView<Group> sorter,
      int limit = 50,
      int offset = 0}) async {
    switch (sorter.sortMethod) {
      case SortMethod.name:
        if (sorter.descending) {
          return await _isarClient.groups
              .where()
              .toDeleteEqualTo(false)
              .sortByNameDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        } else {
          return await _isarClient.groups
              .where()
              .toDeleteEqualTo(false)
              .sortByName()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
      default:
        return getRepoList(limit: limit, offset: offset);
    }
  }

  @override
  Future<List<Group>> getDeleted({int limit = 50, int offset = 0}) async =>
      await _isarClient.groups
          .where()
          .toDeleteEqualTo(true)
          .sortByLastUpdatedDesc()
          .offset(offset)
          .limit(limit)
          .findAll();

  Future<List<int>> getDeleteIDs({DateTime? deleteLimit}) async {
    deleteLimit = deleteLimit ?? Constants.today;
    return await _isarClient.groups
        .where()
        .toDeleteEqualTo(true)
        .filter()
        .lastUpdatedLessThan(deleteLimit)
        .idProperty()
        .findAll();
  }

  Future<List<Group>> getUnsynced() async =>
      await _isarClient.groups.filter().isSyncedEqualTo(false).findAll();

  GroupRepo._internal();
}
