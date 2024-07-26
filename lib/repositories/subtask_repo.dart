import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/task/subtask.dart';
import '../services/isar_service.dart';
import '../services/supabase_service.dart';
import '../util/constants.dart';
import '../util/exceptions.dart';
import '../util/interfaces/repository/model/subtask_repository.dart';
import '../util/interfaces/sortable.dart';

class SubtaskRepo extends ChangeNotifier implements SubtaskRepository {
  static final SubtaskRepo _instance = SubtaskRepo._internal();

  static SubtaskRepo get instance => _instance;

  late final SupabaseClient _supabaseClient;
  late final RealtimeChannel _subtaskStream;

  late final Isar _isarClient;

  bool get isConnected =>
      SupabaseService.instance.isConnected &&
      IsarService.instance.dbSize.value < Constants.supabaseLimit;

  bool get dbFull => IsarService.instance.dbSize.value >= Constants.isarLimit;

  int _subtaskCount = 0;
  bool _subscribed = false;
  bool _initialized = false;

  bool _needsRefreshing = true;
  bool _refreshing = false;
  bool _syncing = false;

  String get uuid => _supabaseClient.auth.currentUser?.id ?? "";

  String? currentUserID;

  // In the case of an unhandled exception during the refresh/sync functions, the flags do not get reset properly.
  // TODO: Refactor Sync/Refresh logic to catch update exceptions.
  // This is meant to be called on a manual-refresh activated by the user in the UI
  @override
  void forceRefreshState() {
    _needsRefreshing = true;
    _syncing = false;
    _refreshing = false;
  }

  @override
  Future<void> init() async {
    if (_initialized) {
      return;
    }
    _isarClient = IsarService.instance.isarClient;

    _supabaseClient = SupabaseService.instance.supabaseClient;

    _initialized = true;
    // I haven't faked the connection channels -> doesn't make sense to.
    if (SupabaseService.instance.offlineOnly) {
      return;
    }
    // Initialize table stream -> only listen on signIn.
    _subtaskStream = _supabaseClient
        .channel("public:subtasks")
        .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: "public",
            table: "subtasks",
            callback: handleUpsert)
        .onPostgresChanges(
            schema: "public",
            table: "subtasks",
            event: PostgresChangeEvent.update,
            callback: handleUpsert)
        .onPostgresChanges(
            schema: "public",
            table: "subtasks",
            event: PostgresChangeEvent.delete,
            callback: handleDelete);

    await handleUserChange();

    if (!_subscribed) {
      _subtaskStream.subscribe();
      _subscribed = true;
    }

    // Listen to auth changes.
    SupabaseService.instance.authSubscription.listen((AuthState data) async {
      final AuthChangeEvent event = data.event;
      switch (event) {
        // case AuthChangeEvent.initialSession:
        //   await handleUserChange();
        //   // OPEN TABLE STREAM -> insert new data.
        //   if (!_subscribed) {
        //     _subtaskStream.subscribe();
        //     _subscribed = true;
        //   }
        case AuthChangeEvent.signedIn:
          await handleUserChange();
          // This should close and re-open the subscription?
          if (!_subscribed) {
            _subtaskStream.subscribe();
            _subscribed = true;
          }
          break;
        case AuthChangeEvent.tokenRefreshed:
          if (!_subscribed) {
            await handleUserChange();
            _subtaskStream.subscribe();
            _subscribed = true;
          }
          break;
        case AuthChangeEvent.signedOut:
          // await _subtaskStream.unsubscribe();
          // _subscribed = false;
          break;
        default:
          break;
      }
    });

    // This is for online stuff.
    SupabaseService.instance.connectionSubscription
        .listen((ConnectivityResult result) async {
      _needsRefreshing = true;
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
    _isarClient.subtasks.watchLazy().listen((_) async {
      await IsarService.instance.updateDBSize();
    });
  }

  Future<void> handleUserChange() async {
    String? newID = _supabaseClient.auth.currentUser?.id;

    // Realtime Changes will handle updated data.
    if (newID == currentUserID) {
      if (_needsRefreshing) {
        await refreshRepo();
        _needsRefreshing = false;
        return;
      }
      return await syncRepo();
    }

    // In the case that the previous currentUserID was null.
    // This implies a new login, or a fresh open.
    // if not online, this will just early return.
    if (null == currentUserID) {
      currentUserID = newID;
      if (_needsRefreshing) {
        await refreshRepo();
        _needsRefreshing = false;
        return;
      }
      return await syncRepo();
    }

    // This implies there is a new user -> clear the DB
    // and insert the new user.
    currentUserID = newID;
    await swapRepo();
  }

  @override
  Future<Subtask> create(Subtask subtask) async {
    if (dbFull) {
      throw LocalLimitExceededException(
          "Database is full. Size: ${IsarService.instance.dbSize.value / 1000000}");
    }
    subtask.isSynced = isConnected;
    late int? id;
    await _isarClient.writeTxn(() async {
      id = await _isarClient.subtasks.put(subtask);
    });

    if (null == id) {
      throw FailureToCreateException("Failed to create Subtask locally \n"
          "Subtask: ${subtask.toString()}\n"
          "Time: ${DateTime.now()}\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (isConnected) {
      Map<String, dynamic> subtaskEntity = subtask.toEntity();
      subtaskEntity["uuid"] = uuid;
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from("subtasks")
          .insert(subtaskEntity)
          .select("id");

      id = response.last["id"];

      if (null == id) {
        throw FailureToUploadException("Failed to sync Subtask on create\n"
            "Subtask: ${subtask.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }

    return subtask;
  }

  @override
  Future<void> delete(Subtask subtask) async {
    subtask.toDelete = true;
    await update(subtask);
  }

  @override
  Future<void> remove(Subtask subtask) async {
    // Delete online
    if (isConnected) {
      try {
        await _supabaseClient.from("subtasks").delete().eq("id", subtask.id);
      } catch (error) {
        throw FailureToDeleteException("Failed to delete Subtask online\n"
            "Subtask: ${subtask.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
    // Delete local
    await _isarClient.writeTxn(() async {
      await _isarClient.subtasks.delete(subtask.id);
    });
  }

  @override
  Future<List<int>> emptyTrash() async {
    if (isConnected) {
      try {
        await _supabaseClient.from("subtasks").delete().eq("toDelete", true);
      } catch (error) {
        throw FailureToDeleteException("Failed to empty trash online\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
    late List<int> deleteIDs;
    await _isarClient.writeTxn(() async {
      deleteIDs = await _isarClient.subtasks
          .where()
          .toDeleteEqualTo(true)
          .idProperty()
          .findAll();
      await _isarClient.subtasks.deleteAll(deleteIDs);
    });
    return deleteIDs;
  }

  @override
  Future<void> clearDB() async {
    if (isConnected) {
      // not sure whether or not to catch errors.
      await _supabaseClient
          .from("subtasks")
          .delete()
          .neq("customViewIndex", -2);
    }

    await _isarClient.writeTxn(() async {
      await _isarClient.subtasks.clear();
    });
  }

  Future<void> clearLocal() async {
    await _isarClient.writeTxn(() async {
      await _isarClient.subtasks.clear();
    });
  }

  @override
  Future<void> deleteSweep({DateTime? upTo}) async {
    List<int> toDeletes = await getDeleteIDs();
    if (isConnected) {
      try {
        await _supabaseClient
            .from("subtasks")
            .delete()
            .inFilter("id", toDeletes);
      } catch (error) {
        throw FailureToDeleteException("Failed to delete subtasks online \n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
    await _isarClient.writeTxn(() async {
      await _isarClient.subtasks.deleteAll(toDeletes);
    });
  }

  @override
  Future<Subtask?> getByID({required int id}) async =>
      await _isarClient.subtasks.where().idEqualTo(id).findFirst();

  @override
  Future<bool> containsID({required int id}) async {
    List<Subtask> duplicates =
        await _isarClient.subtasks.where().idEqualTo(id).findAll();
    return duplicates.isNotEmpty;
  }

  @override
  Future<List<Subtask>> getRepoList({int limit = 50, int offset = 0}) async =>
      await _isarClient.subtasks.where().offset(offset).limit(limit).findAll();

  // No subtask sorting atm.
  @override
  Future<List<Subtask>> getRepoListBy(
          {int limit = Constants.maxNumTasks,
          int offset = 0,
          required SortableView<Subtask> sorter}) async =>
      await getRepoList(limit: limit, offset: offset);

  @override
  Future<int> getTaskSubtasksCount(
          {required int taskID, int limit = Constants.maxNumTasks}) async =>
      await _isarClient.subtasks
          .where()
          .taskIDEqualTo(taskID)
          .filter()
          .toDeleteEqualTo(false)
          .sortByCustomViewIndex()
          .thenByLastUpdatedDesc()
          .limit(limit)
          .count();

  @override
  Future<int> getTaskSubtaskWeight(
          {required int taskID, int limit = Constants.maxNumTasks}) async =>
      await _isarClient.subtasks
          .where()
          .taskIDEqualTo(taskID)
          .filter()
          .toDeleteEqualTo(false)
          .sortByCustomViewIndex()
          .thenByLastUpdatedDesc()
          .limit(limit)
          .weightProperty()
          .sum();

  @override
  Future<List<Subtask>> getRepoByTaskID(
          {required int id, int limit = 50, int offset = 0}) async =>
      await _isarClient.subtasks
          .where()
          .taskIDEqualTo(id)
          .filter()
          .toDeleteEqualTo(false)
          .sortByCompletedDesc()
          .thenByCustomViewIndex()
          .thenByLastUpdated()
          .offset(offset)
          .limit(limit)
          .findAll();

  Future<int> getOnlineCount() async =>
      _supabaseClient.from("subtasks").count(CountOption.exact);

  // Refreshing is prioritized over a soft sync.
  @override
  Future<void> refreshRepo() async {
    if (!isConnected) {
      _refreshing = false;
      _syncing = false;
      return;
    }

    if (_refreshing) {
      return;
    }

    _refreshing = true;
    _syncing = true;

    // Get the set of unsynced data.
    Set<Subtask> unsynced = await getUnsynced().then((_) => _.toSet());

    // Get the online count.
    _subtaskCount = await getOnlineCount();

    // Fetch new data -> by fetchRepo();
    List<Subtask> onlineSubtasks = await fetchRepo();

    List<Subtask> toInsert = List.empty(growable: true);
    for (Subtask onlineSubtask in onlineSubtasks) {
      Subtask? localSubtask = unsynced.lookup(onlineSubtask);
      // Prioritize by last updated -> unsynced data will overwrite new data.
      if (null != localSubtask &&
          onlineSubtask.lastUpdated.isAfter(localSubtask.lastUpdated)) {
        unsynced.remove(localSubtask);
      }
      toInsert.add(onlineSubtask);
    }

    // Clear the DB, then add all new data.
    // Unsynced data will be updated once remaining data has been collected.
    await clearLocal();

    // Put all new data in the db.
    await _isarClient.writeTxn(() async {
      await _isarClient.subtasks.putAll(toInsert);
    });

    insertRemaining(totalFetched: onlineSubtasks.length, unsynced: unsynced);
    _needsRefreshing = false;
    notifyListeners();
  }

  @override
  Future<void> syncRepo() async {
    if (!isConnected) {
      _syncing = false;
      return;
    }

    if (_syncing || _refreshing) {
      return;
    }

    _syncing = true;

    // Get the set of unsynced data.
    Set<Subtask> unsynced = await getUnsynced().then((_) => _.toSet());

    // Get the online count.
    _subtaskCount = await getOnlineCount();

    // Fetch new data -> by fetchRepo();
    List<Subtask> onlineSubtasks = await fetchRepo();

    List<Subtask> toInsert = List.empty(growable: true);
    for (Subtask onlineSubtask in onlineSubtasks) {
      Subtask? localSubtask = unsynced.lookup(onlineSubtask);
      // Prioritize by last updated -> unsynced data will overwrite new data.
      if (null != localSubtask &&
          onlineSubtask.lastUpdated.isAfter(localSubtask.lastUpdated)) {
        unsynced.remove(localSubtask);
      }
      toInsert.add(onlineSubtask);
    }

    // Put all new data in the db.
    await _isarClient.writeTxn(() async {
      await _isarClient.subtasks.putAll(toInsert);
    });

    insertRemaining(totalFetched: onlineSubtasks.length, unsynced: unsynced);
    notifyListeners();
  }

  Future<void> insertRemaining(
      {required int totalFetched, Set<Subtask>? unsynced}) async {
    unsynced = unsynced ?? Set.identity();

    List<Subtask> toInsert = List.empty(growable: true);
    while (totalFetched < _subtaskCount) {
      List<Subtask>? onlineSubtasks = await fetchRepo(offset: totalFetched);

      // If there is no data or connection is lost, break.
      if (onlineSubtasks.isEmpty) {
        break;
      }

      for (Subtask onlineSubtask in onlineSubtasks) {
        Subtask? localSubtask = unsynced.lookup(onlineSubtask);
        // Prioritize by last updated -> unsynced data will overwrite new data.
        if (null != localSubtask &&
            onlineSubtask.lastUpdated.isAfter(localSubtask.lastUpdated)) {
          unsynced.remove(localSubtask);
        }
        toInsert.add(onlineSubtask);
      }

      totalFetched += onlineSubtasks.length;
    }

    await _isarClient.writeTxn(() async {
      await _isarClient.subtasks.putAll(toInsert);
    });

    await updateBatch(unsynced.toList());
    _refreshing = false;
    _syncing = false;
    notifyListeners();
  }

  @override
  Future<List<Subtask>> fetchRepo({int limit = 1000, int offset = 0}) async {
    List<Subtask> data = List.empty(growable: true);
    if (!isConnected) {
      return data;
    }
    try {
      List<Map<String, dynamic>> subtaskEntities = await _supabaseClient
          .from("subtasks")
          .select()
          .eq("uuid", uuid)
          .order("lastUpdated", ascending: false)
          .range(offset, offset + limit);

      for (Map<String, dynamic> entity in subtaskEntities) {
        data.add(Subtask.fromEntity(entity: entity));
      }
    } on Error catch (e, stacktrace) {
      log(e.toString(), stackTrace: stacktrace);
    }
    return data;
  }

  Future<void> swapRepo() async {
    await clearLocal();
    // This clears twice... I haven't figured how to make this more efficient yet.
    await refreshRepo();
  }

  Future<void> handleUpsert(PostgresChangePayload payload) async {
    Subtask subtask = Subtask.fromEntity(entity: payload.newRecord);
    subtask.lastUpdated = DateTime.now();
    await _isarClient.writeTxn(() async {
      await _isarClient.subtasks.put(subtask);
    });

    _subtaskCount = await getOnlineCount();
    notifyListeners();
  }

  Future<void> handleDelete(PostgresChangePayload payload) async {
    int deleteID = payload.oldRecord["id"] as int;
    await _isarClient.writeTxn(() async {
      await _isarClient.subtasks.delete(deleteID);
    });

    _subtaskCount = await getOnlineCount();
    notifyListeners();
  }

  @override
  Future<Subtask> update(Subtask subtask) async {
    subtask.isSynced = isConnected;

    // This is just for error checking.
    late int? id;
    await _isarClient.writeTxn(() async {
      id = await _isarClient.subtasks.put(subtask);
    });

    if (null == id) {
      throw FailureToUpdateException("Failed to update Subtask locally\n"
          "Subtask: ${subtask.toString()}\n"
          "Time: ${DateTime.now()}\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (isConnected) {
      Map<String, dynamic> subtaskEntity = subtask.toEntity();
      subtaskEntity["uuid"] = uuid;
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from("subtasks")
          .upsert(subtaskEntity)
          .select("id");

      id = response.last["id"];
      if (null == id) {
        throw FailureToUploadException("Failed to sync Subtask on update\n"
            "Subtask: ${subtask.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
    return subtask;
  }

  @override
  Future<void> updateBatch(List<Subtask> subtasks) async {
    late List<int?> ids;
    late int? id;

    await _isarClient.writeTxn(() async {
      ids = List<int?>.empty(growable: true);
      for (Subtask subtask in subtasks) {
        subtask.isSynced = isConnected;
        id = await _isarClient.subtasks.put(subtask);
        ids.add(id);
      }
    });
    if (ids.any((id) => null == id)) {
      throw FailureToUpdateException("Failed to update subtasks locally \n"
          "Subtask: ${subtasks.toString()}\n"
          "Time: ${DateTime.now()}\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (isConnected) {
      ids.clear();
      List<Map<String, dynamic>> subtaskEntities = subtasks.map((subtask) {
        Map<String, dynamic> entity = subtask.toEntity();
        entity["uuid"] = uuid;
        return entity;
      }).toList();
      final List<Map<String, dynamic>> responses = await _supabaseClient
          .from("subtasks")
          .upsert(subtaskEntities)
          .select("id");

      ids = responses.map((response) => response["id"] as int?).toList();

      if (ids.any((id) => null == id)) {
        throw FailureToUploadException("Failed to sync subtasks on update \n"
            "Subtask: ${subtasks.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
  }

  // This is more or less just a "grab stuff that has yet to be removed."
  Future<List<int>> getDeleteIDs() async => await _isarClient.subtasks
      .where()
      .toDeleteEqualTo(true)
      .or()
      .taskIDIsNull()
      .idProperty()
      .findAll();

  Future<List<Subtask>> getUnsynced() async =>
      await _isarClient.subtasks.where().isSyncedEqualTo(false).findAll();

  // Not sure whether to use this yet.
  @override
  Future<List<Subtask>> getDeleted({int limit = 50, int offset = 0}) async =>
      await _isarClient.subtasks
          .where()
          .toDeleteEqualTo(true)
          .sortByLastUpdatedDesc()
          .findAll();

  SubtaskRepo._internal();
}
