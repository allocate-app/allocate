import 'dart:async';
import 'dart:developer';

import 'package:allocate/model/task/subtask.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/task/routine.dart';
import '../services/isar_service.dart';
import '../services/supabase_service.dart';
import '../util/constants.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/interfaces/repository/model/routine_repository.dart';
import '../util/interfaces/sortable.dart';

class RoutineRepo extends ChangeNotifier implements RoutineRepository {
  static final RoutineRepo _instance = RoutineRepo._internal();

  static RoutineRepo get instance => _instance;

  // DB Clients.
  late final SupabaseClient _supabaseClient;
  late final RealtimeChannel _routineStream;

  late final Isar _isarClient;

  bool get isConnected =>
      SupabaseService.instance.isConnected &&
      IsarService.instance.dbSize.value < Constants.supabaseLimit;

  bool get dbFull => IsarService.instance.dbSize.value >= Constants.isarLimit;

  int _routineCount = 0;
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
    _routineStream = _supabaseClient
        .channel("public:routines")
        .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: "public",
            table: "routines",
            callback: handleUpsert)
        .onPostgresChanges(
            schema: "public",
            table: "routines",
            event: PostgresChangeEvent.update,
            callback: handleUpsert)
        .onPostgresChanges(
            schema: "public",
            table: "routines",
            event: PostgresChangeEvent.delete,
            callback: handleDelete);

    // Listen to auth changes.
    SupabaseService.instance.authSubscription.listen((AuthState data) async {
      final AuthChangeEvent event = data.event;
      switch (event) {
        case AuthChangeEvent.initialSession:
          await handleUserChange();
          if (!_subscribed) {
            _routineStream.subscribe();
            _subscribed = true;
          }
          break;
        case AuthChangeEvent.signedIn:
          await handleUserChange();
          // OPEN TABLE STREAM -> insert new data.
          if (!_subscribed) {
            _routineStream.subscribe();
            _subscribed = true;
          }
          break;
        case AuthChangeEvent.tokenRefreshed:
          // If not listening to the stream, there hasn't been an update.
          // Sync accordingly.
          if (!_subscribed) {
            await handleUserChange();
            _routineStream.subscribe();
            _subscribed = true;
          }
          break;
        case AuthChangeEvent.signedOut:
          // await _routineStream.unsubscribe();
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
    _isarClient.routines.watchLazy().listen((_) async {
      await IsarService.instance.updateDBSize();
    });

    handleUserChange();
  }

  Future<void> handleUserChange() async {
    String? newID = _supabaseClient.auth.currentUser?.id;

    // Realtime Changes will handle updated data.
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
  Future<Routine> create(Routine routine) async {
    if (dbFull) {
      throw LocalLimitExceededException(
          "Database is full. Size: ${IsarService.instance.dbSize.value / 1000000}");
    }
    routine.isSynced = isConnected;

    late int? id;
    await _isarClient.writeTxn(() async {
      //This will require to be corrected once db is generated.
      id = await _isarClient.routines.put(routine);
    });

    if (null == id) {
      throw FailureToCreateException("Failed to create routine locally\n"
          "Routine: ${routine.toString()}\n"
          "Time: ${DateTime.now()}\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (isConnected) {
      Map<String, dynamic> routineEntity = routine.toEntity();
      routineEntity["uuid"] = uuid;
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from("routines")
          .insert(routineEntity)
          .select("id");

      id = response.last["id"];

      if (null == id) {
        throw FailureToUploadException("Failed to sync routine on create\n"
            "Routine: ${routine.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
    return routine;
  }

  @override
  Future<Routine> update(Routine routine) async {
    routine.isSynced = isConnected;

    // This is just for error checking.
    late int? id;
    await _isarClient.writeTxn(() async {
      id = await _isarClient.routines.put(routine);
    });

    if (null == id) {
      throw FailureToUpdateException("Failed to update routine locally\n"
          "Routine: ${routine.toString()}\n"
          "Time: ${DateTime.now()}\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (isConnected) {
      Map<String, dynamic> routineEntity = routine.toEntity();
      routineEntity["uuid"] = uuid;
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from("routines")
          .upsert(routineEntity)
          .select("id");

      id = response.last["id"] as int?;
      if (null == id) {
        throw FailureToUploadException("Failed to sync routine on update\n"
            "Routine: ${routine.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
    return routine;
  }

  @override
  Future<void> updateBatch(List<Routine> routines) async {
    if (routines.isEmpty) {
      return;
    }

    late List<int?> ids;
    late int? id;

    await _isarClient.writeTxn(() async {
      ids = List<int?>.empty(growable: true);
      for (Routine routine in routines) {
        routine.isSynced = isConnected;
        id = await _isarClient.routines.put(routine);
        ids.add(id);
      }
    });
    if (ids.any((id) => null == id)) {
      throw FailureToUpdateException("Failed to update routines locally\n"
          "Routines: ${routines.toString()}\n"
          "Time: ${DateTime.now()}\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (isConnected) {
      ids.clear();
      List<Map<String, dynamic>> routineEntities = routines.map((routine) {
        Map<String, dynamic> entity = routine.toEntity();

        entity["uuid"] = uuid;
        return entity;
      }).toList();
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from("routines")
          .upsert(routineEntities)
          .select("id");

      ids = response.map((response) => response["id"] as int?).toList();

      if (ids.any((id) => null == id)) {
        throw FailureToUploadException("Failed to sync routines on update\n"
            "Routines: ${routines.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
  }

  @override
  Future<void> delete(Routine routine) async {
    routine.toDelete = true;
    await update(routine);
  }

  @override
  Future<void> remove(Routine routine) async {
    // Delete online
    if (isConnected) {
      try {
        await _supabaseClient.from("routines").delete().eq("id", routine.id);
      } catch (error) {
        throw FailureToDeleteException("Failed to delete Routine online\n"
            "Routine: ${routine.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
    // Delete local
    await _isarClient.writeTxn(() async {
      await _isarClient.routines.delete(routine.id);
    });
  }

  @override
  Future<List<int>> emptyTrash() async {
    if (isConnected) {
      try {
        await _supabaseClient.from("routines").delete().eq("toDelete", true);
      } catch (error) {
        throw FailureToDeleteException("Failed to empty trash online\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
    late List<int> deleteIDs;
    await _isarClient.writeTxn(() async {
      deleteIDs = await _isarClient.routines
          .where()
          .toDeleteEqualTo(true)
          .idProperty()
          .findAll();
      await _isarClient.routines.deleteAll(deleteIDs);
    });
    return deleteIDs;
  }

  @override
  Future<void> clearDB() async {
    if (isConnected) {
      // not sure whether or not to catch errors.
      await _supabaseClient
          .from("routines")
          .delete()
          .neq("customViewIndex", -2);
    }

    await _isarClient.writeTxn(() async {
      await _isarClient.routines.clear();
    });
  }

  Future<void> clearLocal() async {
    await _isarClient.writeTxn(() async {
      await _isarClient.routines.clear();
    });
  }

  // To avoid unnecessary id list passing -> just deleting subtasks here.
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
        await _supabaseClient
            .from("routines")
            .delete()
            .inFilter("id", toDeletes);
        await _supabaseClient
            .from("subtasks")
            .delete()
            .inFilter("id", subtaskIDs);
      } catch (error) {
        throw FailureToDeleteException("Failed to delete routines online \n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
    await _isarClient.writeTxn(() async {
      await _isarClient.routines.deleteAll(toDeletes);
      await _isarClient.subtasks.deleteAll(subtaskIDs);
    });
  }

  Future<int> getOnlineCount() async =>
      _supabaseClient.from("routines").count(CountOption.exact);

  @override
  Future<void> syncRepo() async {
    if (!isConnected) {
      return;
    }

    // Get the set of unsynced data.
    Set<Routine> unsynced = await getUnsynced().then((_) => _.toSet());

    // Get the online count.
    _routineCount = await getOnlineCount();

    // Fetch new data -> by fetchRepo();
    List<Routine> onlineRoutines = await fetchRepo();

    List<Routine> toInsert = List.empty(growable: true);
    for (Routine routine in onlineRoutines) {
      Routine? otherRoutine = unsynced.lookup(routine);
      // Prioritize by last updated -> unsynced data will overwrite new data.
      if (null != otherRoutine &&
          routine.lastUpdated.isAfter(otherRoutine.lastUpdated)) {
        unsynced.remove(otherRoutine);
      }
      toInsert.add(routine);
    }

    // Put all new data in the db.
    await _isarClient.writeTxn(() async {
      await _isarClient.routines.putAll(toInsert);
    });

    // Update the unsynced data.
    await updateBatch(unsynced.toList());

    if (onlineRoutines.length < _routineCount) {
      // Give the db a moment to refresh.
      await Future.delayed(const Duration(seconds: 1));
      insertRemaining(totalFetched: onlineRoutines.length).whenComplete(() {
        notifyListeners();
      });
    }

    notifyListeners();
  }

  Future<void> insertRemaining({required int totalFetched}) async {
    List<Routine> toInsert = List.empty(growable: true);
    while (totalFetched < _routineCount) {
      List<Routine>? newRoutines = await fetchRepo(offset: totalFetched);

      // If there is no data or connection is lost, break.
      if (newRoutines.isEmpty) {
        break;
      }
      toInsert.addAll(newRoutines);
      totalFetched += newRoutines.length;
    }

    await _isarClient.writeTxn(() async {
      await _isarClient.routines.putAll(toInsert);
    });
  }

  @override
  Future<List<Routine>> fetchRepo({int limit = 1000, int offset = 0}) async {
    List<Routine> data = List.empty(growable: true);
    if (!isConnected) {
      return data;
    }
    try {
      List<Map<String, dynamic>> routineEntities = await _supabaseClient
          .from("routines")
          .select()
          .eq("uuid", uuid)
          .order("lastUpdated", ascending: false)
          .range(offset, offset + limit);

      for (Map<String, dynamic> entity in routineEntities) {
        data.add(Routine.fromEntity(entity: entity));
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
    Routine routine = Routine.fromEntity(entity: payload.newRecord);
    await _isarClient.writeTxn(() async {
      await _isarClient.routines.put(routine);
    });

    _routineCount = await getOnlineCount();
    notifyListeners();
  }

  Future<void> handleDelete(PostgresChangePayload payload) async {
    int deleteID = payload.oldRecord["id"] as int;
    await _isarClient.writeTxn(() async {
      await _isarClient.routines.delete(deleteID);
    });

    _routineCount = await getOnlineCount();
    notifyListeners();
  }

  @override
  Future<List<Routine>> search(
          {required String searchString, bool toDelete = false}) async =>
      await _isarClient.routines
          .where()
          .toDeleteEqualTo(toDelete)
          .filter()
          .nameContains(searchString, caseSensitive: false)
          .limit(5)
          .findAll();

  @override
  Future<List<Routine>> mostRecent({int limit = 50}) async =>
      await _isarClient.routines
          .where()
          .sortByLastUpdatedDesc()
          .limit(limit)
          .findAll();

  @override
  Future<Routine?> getByID({required int id}) async =>
      await _isarClient.routines.where().idEqualTo(id).findFirst();

  @override
  Future<List<Routine>> getRepoList({int limit = 50, int offset = 0}) async {
    return await _isarClient.routines
        .where()
        .toDeleteEqualTo(false)
        .sortByCustomViewIndex()
        .thenByLastUpdatedDesc()
        .offset(offset)
        .limit(limit)
        .findAll();
  }

  @override
  Future<List<Routine>> getRepoListBy(
      {int limit = 50,
      int offset = 0,
      required SortableView<Routine> sorter}) async {
    switch (sorter.sortMethod) {
      case SortMethod.name:
        if (sorter.descending) {
          return await _isarClient.routines
              .where()
              .toDeleteEqualTo(false)
              .sortByNameDesc()
              .findAll();
        }
        return await _isarClient.routines
            .where()
            .toDeleteEqualTo(false)
            .sortByName()
            .thenByLastUpdatedDesc()
            .offset(offset)
            .limit(limit)
            .findAll();

      case SortMethod.weight:
        if (sorter.descending) {
          return await _isarClient.routines
              .where()
              .toDeleteEqualTo(false)
              .sortByWeightDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
        return await _isarClient.routines
            .where()
            .toDeleteEqualTo(false)
            .sortByWeight()
            .thenByLastUpdatedDesc()
            .offset(offset)
            .limit(limit)
            .findAll();

      case SortMethod.duration:
        if (sorter.descending) {
          return await _isarClient.routines
              .where()
              .toDeleteEqualTo(false)
              .sortByRealDurationDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
        return await _isarClient.routines
            .where()
            .toDeleteEqualTo(false)
            .sortByRealDuration()
            .thenByLastUpdatedDesc()
            .offset(offset)
            .limit(limit)
            .findAll();

      default:
        return getRepoList(limit: limit, offset: offset);
    }
  }

  @override
  Future<List<Routine>> getDeleted({int limit = 50, int offset = 0}) async =>
      await _isarClient.routines
          .where()
          .toDeleteEqualTo(true)
          .sortByLastUpdatedDesc()
          .offset(offset)
          .limit(limit)
          .findAll();

  Future<List<int>> getDeleteIDs({DateTime? deleteLimit}) async {
    deleteLimit = deleteLimit ?? Constants.today;
    return await _isarClient.routines
        .where()
        .toDeleteEqualTo(true)
        .filter()
        .lastUpdatedLessThan(deleteLimit)
        .idProperty()
        .findAll();
  }

  Future<List<Routine>> getUnsynced() async =>
      await _isarClient.routines.where().isSyncedEqualTo(false).findAll();

  RoutineRepo._internal();
}
