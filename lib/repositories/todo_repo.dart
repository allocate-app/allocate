import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/task/subtask.dart';
import '../model/task/todo.dart';
import '../services/isar_service.dart';
import '../services/supabase_service.dart';
import '../util/constants.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/interfaces/repository/model/todo_repository.dart';
import '../util/interfaces/sortable.dart';

// This notifies when receiving data from the internet.
// Deemed unnecessary to store uuid, but uuid req'd for RLS
// All maps must have a uuid column.
class ToDoRepo extends ChangeNotifier implements ToDoRepository {
  static final ToDoRepo _instance = ToDoRepo._internal();

  static ToDoRepo get instance => _instance;

  late final SupabaseClient _supabaseClient;

  late final RealtimeChannel _toDoStream;

  late final Isar _isarClient;

  bool get isConnected =>
      SupabaseService.instance.isConnected &&
      IsarService.instance.dbSize.value < Constants.supabaseLimit;

  bool get dbFull => IsarService.instance.dbSize.value >= Constants.isarLimit;

  int _toDoCount = 0;
  bool _subscribed = false;
  bool _initialized = false;

  bool _needsRefreshing = true;
  bool _syncing = false;
  bool _refreshing = false;

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
    _toDoStream = _supabaseClient
        .channel("public:toDos")
        .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: "public",
            table: "toDos",
            callback: handleUpsert)
        .onPostgresChanges(
            schema: "public",
            table: "toDos",
            event: PostgresChangeEvent.update,
            callback: handleUpsert)
        .onPostgresChanges(
            schema: "public",
            table: "toDos",
            event: PostgresChangeEvent.delete,
            callback: handleDelete);

    await handleUserChange();

    if (!_subscribed) {
      _toDoStream.subscribe();
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
        //     _toDoStream.subscribe();
        //     _subscribed = true;
        //   }
        case AuthChangeEvent.signedIn:
          await handleUserChange();
          // This should close and re-open the subscription?
          if (!_subscribed) {
            _toDoStream.subscribe();
            _subscribed = true;
          }
          break;
        case AuthChangeEvent.tokenRefreshed:
          if (!_subscribed) {
            await handleUserChange();
            _toDoStream.subscribe();
            _subscribed = true;
          }
          break;
        case AuthChangeEvent.signedOut:
          // await _toDoStream.unsubscribe();
          // _subscribed = false;
          break;
        default:
          break;
      }
    });

    // This is for online stuff.
    // I am unsure as to what the heck I was thinking here.
    SupabaseService.instance.connectionSubscription
        .listen((List<ConnectivityResult> results) async {
      _needsRefreshing = true;

      if (results.last == ConnectivityResult.none) {
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
    _isarClient.toDos.watchLazy().listen((_) async {
      await IsarService.instance.updateDBSize();
    });
  }

  // Refresh: Gather unsynced data, Clear the database, then Sync.
  Future<void> handleUserChange() async {
    String? newID = _supabaseClient.auth.currentUser?.id;

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

  // Offline first -> local operation first.
  @override
  Future<ToDo> create(ToDo toDo) async {
    if (dbFull) {
      throw LocalLimitExceededException(
          "Database is full. Size: ${IsarService.instance.dbSize.value / 1000000}");
    }
    // Get sync => Supabase + internet

    toDo.isSynced = isConnected;

    late int? id;

    await _isarClient.writeTxn(() async {
      id = await _isarClient.toDos.put(toDo);
    });

    if (null == id) {
      throw FailureToCreateException("Failed to create ToDo locally \n"
          "ToDo: ${toDo.toString()}\n"
          "Time: ${DateTime.now()}\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (isConnected) {
      Map<String, dynamic> toDoEntity = toDo.toEntity();
      toDoEntity["uuid"] = _supabaseClient.auth.currentUser!.id;
      final List<Map<String, dynamic>> response =
          await _supabaseClient.from("toDos").insert(toDoEntity).select("id");

      id = response.last["id"];

      if (null == id) {
        throw FailureToUploadException("Failed to sync ToDo on create\n"
            "ToDo: ${toDo.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }

    return toDo;
  }

  // Offline first -> local first
  @override
  Future<ToDo> update(ToDo toDo) async {
    toDo.isSynced = isConnected;

    // This is just for error checking.
    late int? id;

    await _isarClient.writeTxn(() async {
      id = await _isarClient.toDos.put(toDo);
    });

    if (null == id) {
      throw FailureToUpdateException("Failed to update ToDo locally\n"
          "ToDo: ${toDo.toString()}\n"
          "Time: ${DateTime.now()}\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (isConnected) {
      Map<String, dynamic> toDoEntity = toDo.toEntity();
      toDoEntity["uuid"] = _supabaseClient.auth.currentUser!.id;
      final List<Map<String, dynamic>> response =
          await _supabaseClient.from("toDos").upsert(toDoEntity).select("id");

      id = response.last["id"];
      if (null == id) {
        throw FailureToUploadException("Failed to sync ToDo on update\n"
            "ToDo: ${toDo.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }

    return toDo;
  }

  @override
  Future<void> updateBatch(List<ToDo> toDos) async {
    late List<int?> ids;
    late int? id;

    await _isarClient.writeTxn(() async {
      ids = List<int?>.empty(growable: true);
      for (ToDo toDo in toDos) {
        toDo.isSynced = (isConnected);
        id = await _isarClient.toDos.put(toDo);
        ids.add(id);
      }
    });
    if (ids.any((id) => null == id)) {
      throw FailureToUpdateException("Failed to update toDos locally \n"
          "ToDo: ${toDos.toString()}\n"
          "Time: ${DateTime.now()}\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (isConnected) {
      ids.clear();
      List<Map<String, dynamic>> toDoEntities = (toDos).map((toDo) {
        Map<String, dynamic> entity = toDo.toEntity();
        entity["uuid"] = _supabaseClient.auth.currentUser!.id;
        return entity;
      }).toList();
      final List<Map<String, dynamic>> responses =
          await _supabaseClient.from("toDos").upsert(toDoEntities).select("id");

      ids = responses.map((response) => response["id"] as int?).toList();

      if (ids.any((id) => null == id)) {
        throw FailureToUploadException("Failed to sync toDos on update \n"
            "ToDo: ${toDos.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
  }

  @override
  Future<void> delete(ToDo toDo) async {
    toDo.toDelete = true;
    await update(toDo);
  }

  @override
  Future<void> remove(ToDo toDo) async {
    // Delete online
    if (isConnected) {
      try {
        await _supabaseClient.from("toDos").delete().eq("id", toDo.id);
      } catch (error) {
        throw FailureToDeleteException("Failed to delete ToDo online\n"
            "ToDo: ${toDo.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
    // Delete local
    await _isarClient.writeTxn(() async {
      await _isarClient.toDos.delete(toDo.id);
    });
  }

  @override
  Future<List<int>> emptyTrash() async {
    if (isConnected) {
      try {
        await _supabaseClient.from("toDos").delete().eq("toDelete", true);
      } catch (error) {
        throw FailureToDeleteException("Failed to empty trash online\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }

    late List<int> deleteIDs;

    await _isarClient.writeTxn(() async {
      deleteIDs = await _isarClient.toDos
          .where()
          .toDeleteEqualTo(true)
          .idProperty()
          .findAll();
      await _isarClient.toDos.deleteAll(deleteIDs);
    });
    return deleteIDs;
  }

  @override
  Future<void> clearDB() async {
    if (isConnected) {
      // not sure whether or not to catch errors.
      await _supabaseClient.from("toDos").delete().neq("customViewIndex", -2);
    }

    await _isarClient.writeTxn(() async {
      await _isarClient.toDos.clear();
    });
  }

  Future<void> clearLocal() async {
    await _isarClient.writeTxn(() async {
      await _isarClient.toDos.clear();
    });
  }

  @override
  Future<List<int>> deleteFutures({required ToDo deleteFrom}) async {
    List<int> toDelete = await _isarClient.toDos
        .where()
        .repeatIDEqualTo(deleteFrom.repeatID)
        .filter()
        .startDateGreaterThan(deleteFrom.startDate!)
        .repeatableStateEqualTo(RepeatableState.normal)
        .idProperty()
        .findAll();

    // Online
    if (isConnected) {
      try {
        await _supabaseClient.from("toDos").delete().inFilter("id", toDelete);
      } catch (error) {
        throw FailureToDeleteException(
            "Failed to delete future events online \n"
            "ToDo: ${deleteFrom.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }

    // Offline
    await _isarClient.writeTxn(() async {
      await _isarClient.toDos.deleteAll(toDelete);
    });

    return toDelete;
  }

  @override
  Future<void> deleteSweep({DateTime? upTo}) async {
    List<int> toDeletes = await getDeleteIDs(deleteLimit: upTo);
    List<int> subtaskIDs = List.empty(growable: true);
    for (int id in toDeletes) {
      subtaskIDs.addAll(await _isarClient.subtasks
          .where()
          .taskIDEqualTo(id)
          .idProperty()
          .findAll());
    }

    if (isConnected) {
      try {
        await _supabaseClient.from("toDos").delete().inFilter("id", toDeletes);
        await _supabaseClient
            .from("subtasks")
            .delete()
            .inFilter("id", subtaskIDs);
      } catch (error) {
        throw FailureToDeleteException("Failed to delete todos online \n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
    await _isarClient.writeTxn(() async {
      await _isarClient.toDos.deleteAll(toDeletes);
      await _isarClient.subtasks.deleteAll(subtaskIDs);
    });
  }

  Future<int> getOnlineCount() async =>
      _supabaseClient.from("toDos").count(CountOption.exact);

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
    Set<ToDo> unsynced = await getUnsynced().then((_) => _.toSet());

    // Get the online count.
    _toDoCount = await getOnlineCount();

    // Fetch new data -> by fetchRepo();
    List<ToDo> onlineToDos = await fetchRepo();

    List<ToDo> toInsert = List.empty(growable: true);
    for (ToDo onlineToDo in onlineToDos) {
      ToDo? localToDo = unsynced.lookup(onlineToDo);
      // Prioritize by last updated -> unsynced data will overwrite new data
      // during the batch update.
      if (null != localToDo &&
          onlineToDo.lastUpdated.isAfter(localToDo.lastUpdated)) {
        unsynced.remove(localToDo);
      }
      toInsert.add(onlineToDo);
    }

    // Clear the DB, then add all new data.
    // Unsynced data will be updated once remaining data has been collected.
    await clearLocal();

    await _isarClient.writeTxn(() async {
      await _isarClient.toDos.putAll(toInsert);
    });

    insertRemaining(totalFetched: onlineToDos.length, unsynced: unsynced);
    notifyListeners();
  }

  // This doesn't currently throw exceptions, as these are technically less critical.
  // Most function happens offline.
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
    Set<ToDo> unsynced = await getUnsynced().then((_) => _.toSet());

    // Get the online count.
    _toDoCount = await getOnlineCount();

    // Fetch new data -> by fetchRepo();
    List<ToDo> onlineToDos = await fetchRepo();

    List<ToDo> toInsert = List.empty(growable: true);
    for (ToDo onlineToDo in onlineToDos) {
      ToDo? localToDo = unsynced.lookup(onlineToDo);
      // Prioritize by last updated -> unsynced data will overwrite new data
      // during the batch update.
      if (null != localToDo &&
          onlineToDo.lastUpdated.isAfter(localToDo.lastUpdated)) {
        unsynced.remove(localToDo);
      }
      toInsert.add(onlineToDo);
    }

    // Put all new data in the db.
    await _isarClient.writeTxn(() async {
      await _isarClient.toDos.putAll(toInsert);
    });

    insertRemaining(totalFetched: onlineToDos.length, unsynced: unsynced);

    notifyListeners();
  }

  Future<void> insertRemaining(
      {required int totalFetched, Set<ToDo>? unsynced}) async {
    unsynced = unsynced ?? Set.identity();

    List<ToDo> toInsert = List.empty(growable: true);
    while (totalFetched < _toDoCount) {
      List<ToDo>? onlineToDos = await fetchRepo(offset: totalFetched);

      // If there is no data or connection is lost, break.
      if (onlineToDos.isEmpty) {
        break;
      }
      for (ToDo onlineToDo in onlineToDos) {
        ToDo? localToDo = unsynced.lookup(onlineToDo);
        // Prioritize by last updated -> unsynced data will overwrite new data
        // during the batch update.
        if (null != localToDo &&
            onlineToDo.lastUpdated.isAfter(localToDo.lastUpdated)) {
          unsynced.remove(localToDo);
        }
        toInsert.add(onlineToDo);
      }
      totalFetched += onlineToDos.length;
    }

    await _isarClient.writeTxn(() async {
      await _isarClient.toDos.putAll(toInsert);
    });

    await updateBatch(unsynced.toList());
    _syncing = false;
    _refreshing = false;

    notifyListeners();
  }

  @override
  Future<List<ToDo>> fetchRepo({int limit = 1000, int offset = 0}) async {
    List<ToDo> data = List.empty(growable: true);
    if (!isConnected) {
      return data;
    }

    try {
      List<Map<String, dynamic>> toDoEntities = await _supabaseClient
          .from("toDos")
          .select()
          .eq("uuid", uuid)
          .order("lastUpdated", ascending: false)
          .range(offset, offset + limit);
      for (Map<String, dynamic> entity in toDoEntities) {
        data.add(ToDo.fromEntity(entity: entity));
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
    ToDo toDo = ToDo.fromEntity(entity: payload.newRecord);
    toDo.lastUpdated = DateTime.now();
    await _isarClient.writeTxn(() async {
      await _isarClient.toDos.put(toDo);
    });

    _toDoCount = await getOnlineCount();
    notifyListeners();
  }

  Future<void> handleDelete(PostgresChangePayload payload) async {
    int deleteID = payload.oldRecord["id"] as int;
    await _isarClient.writeTxn(() async {
      await _isarClient.toDos.delete(deleteID);
    });

    _toDoCount = await getOnlineCount();
    notifyListeners();
  }

  @override
  Future<List<ToDo>> search(
          {required String searchString, bool toDelete = false}) async =>
      await _isarClient.toDos
          .where()
          .toDeleteEqualTo(toDelete)
          .filter()
          .nameContains(searchString, caseSensitive: false)
          .group((q) => q
              .repeatableStateEqualTo(RepeatableState.normal)
              .or()
              .repeatableStateEqualTo(RepeatableState.delta))
          .limit(5)
          .findAll();

  @override
  Future<List<ToDo>> mostRecent({int limit = Constants.intMax}) async =>
      await _isarClient.toDos
          .where()
          .toDeleteEqualTo(false)
          .filter()
          .group((q) => q
              .repeatableStateEqualTo(RepeatableState.normal)
              .or()
              .repeatableStateEqualTo(RepeatableState.delta))
          .sortByLastUpdatedDesc()
          .limit(limit)
          .findAll();

  @override
  Future<ToDo?> getByID({required int id}) async =>
      await _isarClient.toDos.where().idEqualTo(id).findFirst();

  @override
  Future<bool> containsID({required int id}) async {
    List<ToDo> duplicates =
        await _isarClient.toDos.where().idEqualTo(id).findAll();
    return duplicates.isNotEmpty;
  }

  @override
  Future<List<ToDo>> getRepoList(
          {int limit = Constants.intMax,
          int offset = 0,
          bool completed = false}) async =>
      await _isarClient.toDos
          .where()
          .completedEqualTo(completed)
          .filter()
          .toDeleteEqualTo(false)
          .group((q) => q
              .repeatableStateEqualTo(RepeatableState.normal)
              .or()
              .repeatableStateEqualTo(RepeatableState.delta))
          .sortByCustomViewIndex()
          .thenByLastUpdatedDesc()
          .offset(offset)
          .limit(limit)
          .findAll();

  @override
  Future<List<ToDo>> getRepoListBy(
      {int limit = Constants.intMax,
      int offset = 0,
      bool completed = false,
      required SortableView<ToDo> sorter}) async {
    switch (sorter.sortMethod) {
      case SortMethod.name:
        if (sorter.descending) {
          return await _isarClient.toDos
              .where()
              .completedEqualTo(completed)
              .filter()
              .toDeleteEqualTo(false)
              .group((q) => q
                  .repeatableStateEqualTo(RepeatableState.normal)
                  .or()
                  .repeatableStateEqualTo(RepeatableState.delta))
              .sortByNameDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
        return await _isarClient.toDos
            .where()
            .completedEqualTo(completed)
            .filter()
            .toDeleteEqualTo(false)
            .group((q) => q
                .repeatableStateEqualTo(RepeatableState.normal)
                .or()
                .repeatableStateEqualTo(RepeatableState.delta))
            .sortByName()
            .thenByLastUpdatedDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
      case SortMethod.due_date:
        if (sorter.descending) {
          return await _isarClient.toDos
              .where()
              .completedEqualTo(completed)
              .filter()
              .toDeleteEqualTo(false)
              .group((q) => q
                  .repeatableStateEqualTo(RepeatableState.normal)
                  .or()
                  .repeatableStateEqualTo(RepeatableState.delta))
              .sortByDueDateDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
        return await _isarClient.toDos
            .where()
            .completedEqualTo(completed)
            .filter()
            .toDeleteEqualTo(false)
            .group((q) => q
                .repeatableStateEqualTo(RepeatableState.normal)
                .or()
                .repeatableStateEqualTo(RepeatableState.delta))
            .sortByDueDate()
            .thenByLastUpdatedDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
      case SortMethod.weight:
        if (sorter.descending) {
          return await _isarClient.toDos
              .where()
              .completedEqualTo(completed)
              .filter()
              .toDeleteEqualTo(false)
              .group((q) => q
                  .repeatableStateEqualTo(RepeatableState.normal)
                  .or()
                  .repeatableStateEqualTo(RepeatableState.delta))
              .sortByWeightDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
        return await _isarClient.toDos
            .where()
            .completedEqualTo(completed)
            .filter()
            .toDeleteEqualTo(false)
            .group((q) => q
                .repeatableStateEqualTo(RepeatableState.normal)
                .or()
                .repeatableStateEqualTo(RepeatableState.delta))
            .sortByWeight()
            .thenByLastUpdatedDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
      case SortMethod.priority:
        if (sorter.descending) {
          return await _isarClient.toDos
              .where()
              .completedEqualTo(completed)
              .filter()
              .toDeleteEqualTo(false)
              .group((q) => q
                  .repeatableStateEqualTo(RepeatableState.normal)
                  .or()
                  .repeatableStateEqualTo(RepeatableState.delta))
              .sortByPriorityDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
        return await _isarClient.toDos
            .where()
            .completedEqualTo(completed)
            .filter()
            .toDeleteEqualTo(false)
            .group((q) => q
                .repeatableStateEqualTo(RepeatableState.normal)
                .or()
                .repeatableStateEqualTo(RepeatableState.delta))
            .sortByPriority()
            .thenByLastUpdatedDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
      case SortMethod.duration:
        if (sorter.descending) {
          return await _isarClient.toDos
              .where()
              .completedEqualTo(completed)
              .filter()
              .toDeleteEqualTo(false)
              .group((q) => q
                  .repeatableStateEqualTo(RepeatableState.normal)
                  .or()
                  .repeatableStateEqualTo(RepeatableState.delta))
              .sortByRealDurationDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
        return await _isarClient.toDos
            .where()
            .completedEqualTo(completed)
            .filter()
            .toDeleteEqualTo(false)
            .group((q) => q
                .repeatableStateEqualTo(RepeatableState.normal)
                .or()
                .repeatableStateEqualTo(RepeatableState.delta))
            .sortByRealDuration()
            .thenByLastUpdatedDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
      default:
        return getRepoList(limit: limit, offset: offset, completed: completed);
    }
  }

  @override
  Future<List<ToDo>> getDeleted(
          {int limit = Constants.intMax, int offset = 0}) async =>
      await _isarClient.toDos
          .where()
          .toDeleteEqualTo(true)
          .filter()
          .group((q) => q
              .repeatableStateEqualTo(RepeatableState.normal)
              .or()
              .repeatableStateEqualTo(RepeatableState.delta))
          .sortByLastUpdatedDesc()
          .offset(offset)
          .limit(limit)
          .findAll();

  @override
  Future<List<ToDo>> getCompleted(
          {required SortableView<ToDo> sorter,
          int limit = Constants.intMax,
          int offset = 0}) async =>
      await getRepoListBy(
          sorter: sorter, limit: limit, offset: offset, completed: true);

  @override
  Future<List<ToDo>> getMyDay(
      {required SortableView<ToDo> sorter,
      int limit = Constants.intMax,
      int offset = 0}) async {
    switch (sorter.sortMethod) {
      case SortMethod.name:
        if (sorter.descending) {
          return await _isarClient.toDos
              .where()
              // .completedEqualTo(false)
              .myDayEqualTo(true)
              .filter()
              .toDeleteEqualTo(false)
              .group((q) => q
                  .repeatableStateEqualTo(RepeatableState.normal)
                  .or()
                  .repeatableStateEqualTo(RepeatableState.delta))
              .sortByNameDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
        return await _isarClient.toDos
            .where()
            // .completedEqualTo(false)
            .myDayEqualTo(true)
            .filter()
            .toDeleteEqualTo(false)
            .group((q) => q
                .repeatableStateEqualTo(RepeatableState.normal)
                .or()
                .repeatableStateEqualTo(RepeatableState.delta))
            .sortByName()
            .thenByLastUpdatedDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
      case SortMethod.due_date:
        if (sorter.descending) {
          return await _isarClient.toDos
              .where()
              // .completedEqualTo(false)
              .myDayEqualTo(true)
              .filter()
              .toDeleteEqualTo(false)
              .group((q) => q
                  .repeatableStateEqualTo(RepeatableState.normal)
                  .or()
                  .repeatableStateEqualTo(RepeatableState.delta))
              .sortByDueDateDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
        return await _isarClient.toDos
            .where()
            // .completedEqualTo(false)
            .myDayEqualTo(true)
            .filter()
            .toDeleteEqualTo(false)
            .group((q) => q
                .repeatableStateEqualTo(RepeatableState.normal)
                .or()
                .repeatableStateEqualTo(RepeatableState.delta))
            .sortByDueDate()
            .thenByLastUpdatedDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
      case SortMethod.weight:
        if (sorter.descending) {
          return await _isarClient.toDos
              .where()
              // .completedEqualTo(false)
              .myDayEqualTo(true)
              .filter()
              .toDeleteEqualTo(false)
              .group((q) => q
                  .repeatableStateEqualTo(RepeatableState.normal)
                  .or()
                  .repeatableStateEqualTo(RepeatableState.delta))
              .sortByWeightDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
        return await _isarClient.toDos
            .where()
            // .completedEqualTo(false)
            .myDayEqualTo(true)
            .filter()
            .toDeleteEqualTo(false)
            .group((q) => q
                .repeatableStateEqualTo(RepeatableState.normal)
                .or()
                .repeatableStateEqualTo(RepeatableState.delta))
            .sortByWeight()
            .thenByLastUpdatedDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
      case SortMethod.priority:
        if (sorter.descending) {
          return await _isarClient.toDos
              .where()
              // .completedEqualTo(false)
              .myDayEqualTo(true)
              .filter()
              .toDeleteEqualTo(false)
              .group((q) => q
                  .repeatableStateEqualTo(RepeatableState.normal)
                  .or()
                  .repeatableStateEqualTo(RepeatableState.delta))
              .sortByPriorityDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
        return await _isarClient.toDos
            .where()
            // .completedEqualTo(false)
            .myDayEqualTo(true)
            .filter()
            .toDeleteEqualTo(false)
            .group((q) => q
                .repeatableStateEqualTo(RepeatableState.normal)
                .or()
                .repeatableStateEqualTo(RepeatableState.delta))
            .sortByPriority()
            .thenByLastUpdatedDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
      case SortMethod.duration:
        if (sorter.descending) {
          return await _isarClient.toDos
              .where()
              // .completedEqualTo(false)
              .myDayEqualTo(true)
              .filter()
              .toDeleteEqualTo(false)
              .group((q) => q
                  .repeatableStateEqualTo(RepeatableState.normal)
                  .or()
                  .repeatableStateEqualTo(RepeatableState.delta))
              .sortByRealDurationDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
        return await _isarClient.toDos
            .where()
            // .completedEqualTo(false)
            .myDayEqualTo(true)
            .filter()
            .toDeleteEqualTo(false)
            .group((q) => q
                .repeatableStateEqualTo(RepeatableState.normal)
                .or()
                .repeatableStateEqualTo(RepeatableState.delta))
            .sortByRealDuration()
            .thenByLastUpdatedDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
      default:
        return await _isarClient.toDos
            .where()
            // .completedEqualTo(false)
            .myDayEqualTo(true)
            .filter()
            .toDeleteEqualTo(false)
            .group((q) => q
                .repeatableStateEqualTo(RepeatableState.normal)
                .or()
                .repeatableStateEqualTo(RepeatableState.delta))
            .sortByCustomViewIndex()
            .thenByLastUpdatedDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
    }
  }

  @override
  Future<int> getMyDayWeight({int limit = Constants.intMax}) async =>
      await _isarClient.toDos
          .where()
          .myDayEqualTo(true)
          .filter()
          .toDeleteEqualTo(false)
          .group((q) => q
              .repeatableStateEqualTo(RepeatableState.normal)
              .or()
              .repeatableStateEqualTo(RepeatableState.delta))
          // .completedEqualTo(false)
          .weightProperty()
          .sum();

  @override
  Future<List<ToDo>> getRepoByGroupID(
          {required int groupID,
          int limit = Constants.intMax,
          int offset = 0}) async =>
      await _isarClient.toDos
          .where()
          .groupIDEqualTo(groupID)
          .filter()
          .toDeleteEqualTo(false)
          .group((q) => q
              .repeatableStateEqualTo(RepeatableState.normal)
              .or()
              .repeatableStateEqualTo(RepeatableState.delta))
          .sortByCompletedDesc()
          .thenByGroupIndex()
          .thenByLastUpdated()
          .offset(offset)
          .limit(limit)
          .findAll();

  // This needs to capture "deleted" deltas.
  @override
  Future<List<ToDo>> getRepeatables({DateTime? now}) async =>
      await _isarClient.toDos
          .where()
          .repeatableEqualTo(true)
          .filter()
          .repeatableStateEqualTo(RepeatableState.normal)
          .originalStartLessThan(now ?? Constants.today)
          .findAll();

  @override
  Future<ToDo?> getNextRepeat({required int repeatID, DateTime? now}) async =>
      await _isarClient.toDos
          .where()
          .repeatableEqualTo(true)
          .filter()
          .repeatIDEqualTo(repeatID)
          .repeatableStateEqualTo(RepeatableState.normal)
          .originalStartLessThan(now ?? Constants.today)
          .findFirst();

  @override
  Future<ToDo?> getDelta(
          {required DateTime onDate, required int repeatID}) async =>
      await _isarClient.toDos
          .where()
          .repeatableStateEqualTo(RepeatableState.delta)
          .filter()
          .originalStartEqualTo(onDate)
          .findFirst();

  @override
  Future<List<ToDo>> getDeltas({DateTime? now, required int repeatID}) async =>
      await _isarClient.toDos
          .where()
          .repeatableStateEqualTo(RepeatableState.delta)
          .filter()
          .repeatIDEqualTo(repeatID)
          .originalStartGreaterThan(now ?? Constants.today)
          .findAll();

  @override
  Future<ToDo?> getTemplate({required int repeatID}) async =>
      await _isarClient.toDos
          .where()
          .repeatableStateEqualTo(RepeatableState.template)
          .filter()
          .repeatIDEqualTo(repeatID)
          .toDeleteEqualTo(false)
          .findFirst();

  Future<List<int>> getDeleteIDs({DateTime? deleteLimit}) async {
    deleteLimit = deleteLimit ?? Constants.today;
    return await _isarClient.toDos
        .where()
        .toDeleteEqualTo(true)
        .filter()
        .lastUpdatedLessThan(deleteLimit)
        .idProperty()
        .findAll();
  }

  Future<List<ToDo>> getUnsynced() async =>
      await _isarClient.toDos.where().isSyncedEqualTo(false).findAll();

  @override
  Future<List<ToDo>> getRange({DateTime? start, DateTime? end}) async {
    start = start ?? DateTime.now().copyWith(day: 1);
    end = end ?? start.copyWith(month: start.month + 1);
    return await _isarClient.toDos
        .where()
        .dueDateBetween(start, end)
        .filter()
        .toDeleteEqualTo(false)
        .repeatableStateEqualTo(RepeatableState.normal)
        .findAll();
  }

  @override
  Future<List<ToDo>> getUpcoming(
          {int limit = Constants.intMax, int offset = 0}) async =>
      await _isarClient.toDos
          .where()
          .dueDateGreaterThan(DateTime.now())
          .filter()
          .toDeleteEqualTo(false)
          .completedEqualTo(false)
          .group((q) => q
              .repeatableStateEqualTo(RepeatableState.normal)
              .or()
              .repeatableStateEqualTo(RepeatableState.delta))
          .sortByDueDate()
          .thenByLastUpdatedDesc()
          .offset(offset)
          .limit(limit)
          .findAll();

  @override
  Future<List<ToDo>> getOverdues(
          {int limit = Constants.intMax, int offset = 0}) async =>
      await _isarClient.toDos
          .where()
          .dueDateIsNotNull()
          .filter()
          .dueDateLessThan(DateTime.now())
          .toDeleteEqualTo(false)
          .completedEqualTo(false)
          .group((q) => q
              .repeatableStateEqualTo(RepeatableState.normal)
              .or()
              .repeatableStateEqualTo(RepeatableState.delta))
          .sortByDueDateDesc()
          .thenByLastUpdatedDesc()
          .offset(offset)
          .limit(limit)
          .findAll();

  @override
  Future<int> getGroupToDoCount({required int groupID}) async =>
      await _isarClient.toDos
          .where()
          .groupIDEqualTo(groupID)
          .filter()
          .toDeleteEqualTo(false)
          .group((q) => q
              .repeatableStateEqualTo(RepeatableState.normal)
              .or()
              .repeatableStateEqualTo(RepeatableState.delta))
          .count();

  // CONSTRUCTOR
  ToDoRepo._internal();
}
