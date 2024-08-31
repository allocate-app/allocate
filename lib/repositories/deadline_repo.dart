import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/task/deadline.dart';
import '../services/isar_service.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../util/constants.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/interfaces/i_repeatable.dart';
import '../util/interfaces/repository/model/deadline_repository.dart';
import '../util/interfaces/sortable.dart';

class DeadlineRepo extends ChangeNotifier implements DeadlineRepository {
  static final DeadlineRepo _instance = DeadlineRepo._internal();

  static DeadlineRepo get instance => _instance;

  //DB Clients.
  late final SupabaseClient _supabaseClient;

  late final RealtimeChannel _deadlineStream;

  late final Isar _isarClient;

  bool get isConnected =>
      SupabaseService.instance.isConnected &&
      IsarService.instance.dbSize.value < Constants.supabaseLimit;

  bool get dbFull => IsarService.instance.dbSize.value >= Constants.isarLimit;

  int _deadlineCount = 0;
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
    _deadlineStream = _supabaseClient
        .channel("public:deadlines")
        .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: "public",
            table: "deadlines",
            callback: handleUpsert)
        .onPostgresChanges(
            schema: "public",
            table: "deadlines",
            event: PostgresChangeEvent.update,
            callback: handleUpsert)
        .onPostgresChanges(
            schema: "public",
            table: "deadlines",
            event: PostgresChangeEvent.delete,
            callback: handleDelete);

    await handleUserChange();

    if (!_subscribed) {
      _deadlineStream.subscribe();
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
        //     _deadlineStream.subscribe();
        //     _subscribed = true;
        //   }
        case AuthChangeEvent.signedIn:
          await handleUserChange();
          // This should close and re-open the subscription?
          if (!_subscribed) {
            _deadlineStream.subscribe();
            _subscribed = true;
          }
          break;
        case AuthChangeEvent.tokenRefreshed:
          if (!_subscribed) {
            await handleUserChange();
            _deadlineStream.subscribe();
            _subscribed = true;
          }
          break;
        case AuthChangeEvent.signedOut:
          // await _deadlineStream.unsubscribe();
          // _subscribed = false;
          break;
        default:
          break;
      }
    });

    // This is for online stuff.
    SupabaseService.instance.connectionSubscription
        .listen((List<ConnectivityResult> result) async {
      _needsRefreshing = true;
      if (result.last == ConnectivityResult.none) {
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
    _isarClient.deadlines.watchLazy().listen((_) async {
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
    return await swapRepo();
  }

  @override
  Future<Deadline> create(Deadline deadline) async {
    if (dbFull) {
      throw LocalLimitExceededException(
          "Database is full. Size: ${IsarService.instance.dbSize.value / 1000000}");
    }
    deadline.isSynced = isConnected;
    late int? id;

    await _isarClient.writeTxn(() async {
      id = await _isarClient.deadlines.put(deadline);
    });

    if (null == id) {
      throw FailureToCreateException("Failed to create deadline locally\n"
          "Deadline: ${deadline.toString()}\n"
          "Time: $Constants.today\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (isConnected) {
      Map<String, dynamic> deadlineEntity = deadline.toEntity();
      deadlineEntity["uuid"] = uuid;
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from("deadlines")
          .insert(deadlineEntity)
          .select("id");
      id = response.last["id"];
      if (null == id) {
        throw FailureToUploadException("Failed to sync deadline on create\n"
            "Deadline: ${deadline.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
    return deadline;
  }

  @override
  Future<Deadline> update(Deadline deadline) async {
    deadline.isSynced = isConnected;

    late int? id;
    await _isarClient.writeTxn(() async {
      id = await _isarClient.deadlines.put(deadline);
    });

    if (null == id) {
      throw FailureToUpdateException("Failed to update deadline locally\n"
          "Deadline: ${deadline.toString()}\n"
          "Time: $Constants.today\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (isConnected) {
      Map<String, dynamic> deadlineEntity = deadline.toEntity();
      deadlineEntity["uuid"] = uuid;
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from("deadlines")
          .upsert(deadlineEntity)
          .select("id");

      id = response.last["id"];

      if (null == id) {
        throw FailureToUploadException("Failed to sync deadline on update\n"
            "Deadline: ${deadline.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
    return deadline;
  }

  @override
  Future<void> updateBatch(List<Deadline> deadlines) async {
    late List<int?> ids;
    late int? id;
    await _isarClient.writeTxn(() async {
      ids = List<int?>.empty(growable: true);
      for (Deadline deadline in deadlines) {
        deadline.isSynced = isConnected;
        id = await _isarClient.deadlines.put(deadline);
        ids.add(id);
      }
    });
    if (ids.any((id) => null == id)) {
      throw FailureToUpdateException("Failed to update deadlines locally\n"
          "Deadline: ${deadlines.toString()}\n"
          "Time: $Constants.today\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (isConnected) {
      ids.clear();
      List<Map<String, dynamic>> deadlineEntities = deadlines.map((deadline) {
        Map<String, dynamic> entity = deadline.toEntity();
        entity["uuid"] = uuid;
        return entity;
      }).toList();
      for (Map<String, dynamic> deadlineEntity in deadlineEntities) {
        final List<Map<String, dynamic>> response = await _supabaseClient
            .from("deadlines")
            .update(deadlineEntity)
            .select("id");
        id = response.last["id"];
        ids.add(id);
      }
      if (ids.any((id) => null == id)) {
        throw FailureToUploadException("Failed to sync deadlines on update\n"
            "Deadline: ${deadlines.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
  }

  @override
  Future<void> delete(Deadline deadline) async {
    deadline.toDelete = true;
    await update(deadline);
  }

  @override
  Future<void> remove(Deadline deadline) async {
    // Delete online
    if (isConnected) {
      try {
        await _supabaseClient.from("deadlines").delete().eq("id", deadline.id);
      } catch (error) {
        throw FailureToDeleteException("Failed to delete Deadline online\n"
            "Deadline: ${deadline.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
    // Delete local
    await _isarClient.writeTxn(() async {
      await _isarClient.deadlines.delete(deadline.id);
    });
  }

  @override
  Future<List<int>> emptyTrash() async {
    if (isConnected) {
      try {
        await _supabaseClient.from("deadlines").delete().eq("toDelete", true);
      } catch (error) {
        throw FailureToDeleteException("Failed to empty trash online\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
    late List<int> deleteIDs;
    await _isarClient.writeTxn(() async {
      deleteIDs = await _isarClient.deadlines
          .where()
          .toDeleteEqualTo(true)
          .idProperty()
          .findAll();
      await _isarClient.deadlines.deleteAll(deleteIDs);
    });
    return deleteIDs;
  }

  @override
  Future<void> clearDB() async {
    if (isConnected) {
      // not sure whether or not to catch errors.
      await _supabaseClient
          .from("deadlines")
          .delete()
          .neq("customViewIndex", -2);
    }

    await _isarClient.writeTxn(() async {
      await _isarClient.deadlines.clear();
    });
  }

  Future<void> clearLocal() async {
    await _isarClient.writeTxn(() async {
      await _isarClient.deadlines.clear();
    });
  }

  @override
  Future<List<int>> deleteFutures({required IRepeatable deleteFrom}) async {
    List<int> toDelete = await _isarClient.deadlines
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
        await _supabaseClient
            .from("deadlines")
            .delete()
            .inFilter("id", toDelete);
      } catch (error) {
        throw FailureToDeleteException(
            "Failed to delete future events online \n"
            "Deadline: ${deleteFrom.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }

    // Offline
    await _isarClient.writeTxn(() async {
      await _isarClient.deadlines.deleteAll(toDelete);
    });

    return toDelete;
  }

  @override
  Future<void> deleteSweep({DateTime? upTo}) async {
    List<int> toDeletes = await getDeleteIDs(deleteLimit: upTo);

    if (isConnected) {
      try {
        await _supabaseClient
            .from("deadlines")
            .delete()
            .inFilter("id", toDeletes);
      } catch (error) {
        throw FailureToDeleteException("Failed to delete deadlines online \n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
    await _isarClient.writeTxn(() async {
      await _isarClient.deadlines.deleteAll(toDeletes);
    });
  }

  Future<int> getOnlineCount() async =>
      _supabaseClient.from("deadlines").count(CountOption.exact);

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
    Set<Deadline> unsynced = await getUnsynced().then((_) => _.toSet());

    // Get the online count.
    _deadlineCount = await getOnlineCount();

    // Fetch new data -> by fetchRepo();
    List<Deadline> onlineDeadlines = await fetchRepo();

    List<Deadline> toInsert = List.empty(growable: true);
    for (Deadline onlineDeadline in onlineDeadlines) {
      Deadline? localDeadline = unsynced.lookup(onlineDeadline);
      // Prioritize by last updated -> unsynced data will overwrite new data
      // during the batch update.
      if (null != localDeadline &&
          onlineDeadline.lastUpdated.isAfter(localDeadline.lastUpdated)) {
        unsynced.remove(localDeadline);
      }
      toInsert.add(onlineDeadline);
    }

    // Clear the DB, then add all new data.
    // Unsynced data will be updated once remaining data has been collected.
    await clearLocal();

    await _isarClient.writeTxn(() async {
      await _isarClient.deadlines.putAll(toInsert);
    });

    insertRemaining(totalFetched: onlineDeadlines.length, unsynced: unsynced);
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
    Set<Deadline> unsynced = await getUnsynced().then((_) => _.toSet());

    // Get the online count.
    _deadlineCount = await getOnlineCount();

    // Fetch new data -> by fetchRepo();
    List<Deadline> onlineDeadlines = await fetchRepo();

    List<Deadline> toInsert = List.empty(growable: true);
    for (Deadline onlineDeadline in onlineDeadlines) {
      Deadline? localDeadline = unsynced.lookup(onlineDeadline);
      // Prioritize by last updated -> unsynced data will overwrite new data
      // during the batch update.
      if (null != localDeadline &&
          onlineDeadline.lastUpdated.isAfter(localDeadline.lastUpdated)) {
        unsynced.remove(localDeadline);
      }
      toInsert.add(onlineDeadline);
    }

    // Put all new data in the db.
    await _isarClient.writeTxn(() async {
      await _isarClient.deadlines.putAll(toInsert);
    });

    insertRemaining(totalFetched: onlineDeadlines.length, unsynced: unsynced);

    notifyListeners();
  }

  Future<void> insertRemaining(
      {required int totalFetched, Set<Deadline>? unsynced}) async {
    unsynced = unsynced ?? Set.identity();

    List<Deadline> toInsert = List.empty(growable: true);
    while (totalFetched < _deadlineCount) {
      List<Deadline>? onlineDeadlines = await fetchRepo(offset: totalFetched);

      // If there is no data or connection is lost, break.
      if (onlineDeadlines.isEmpty) {
        break;
      }
      for (Deadline onlineDeadline in onlineDeadlines) {
        Deadline? localDeadline = unsynced.lookup(onlineDeadline);
        // Prioritize by last updated -> unsynced data will overwrite new data
        // during the batch update.
        if (null != localDeadline &&
            onlineDeadline.lastUpdated.isAfter(localDeadline.lastUpdated)) {
          unsynced.remove(localDeadline);
        }
        toInsert.add(onlineDeadline);
      }
      totalFetched += onlineDeadlines.length;
    }

    await _isarClient.writeTxn(() async {
      await _isarClient.deadlines.putAll(toInsert);
    });

    await updateBatch(unsynced.toList());
    _syncing = false;
    _refreshing = false;
    notifyListeners();
  }

  @override
  Future<List<Deadline>> fetchRepo({int limit = 1000, int offset = 0}) async {
    List<Deadline> data = List.empty(growable: true);
    if (!isConnected) {
      return data;
    }
    try {
      List<Map<String, dynamic>> deadlineEntities = await _supabaseClient
          .from("deadlines")
          .select()
          .eq("uuid", uuid)
          .order("lastUpdated", ascending: false)
          .range(offset, offset + limit);

      for (Map<String, dynamic> entity in deadlineEntities) {
        data.add(Deadline.fromEntity(entity: entity));
      }
    } on Error catch (e, stacktrace) {
      log(e.toString(), stackTrace: stacktrace);
    }
    return data;
  }

  Future<void> swapRepo() async {
    NotificationService.instance.cancelAllNotifications();
    // _deadlineStream.unsubscribe();
    // _subscribed = false;
    await clearLocal();
    await refreshRepo();
  }

  Future<void> handleUpsert(PostgresChangePayload payload) async {
    Deadline deadline = Deadline.fromEntity(entity: payload.newRecord);
    deadline.lastUpdated = DateTime.now();
    await _isarClient.writeTxn(() async {
      await _isarClient.deadlines.put(deadline);
    });

    _deadlineCount = await getOnlineCount();
    notifyListeners();
  }

  Future<void> handleDelete(PostgresChangePayload payload) async {
    int deleteID = payload.oldRecord["id"] as int;
    await _isarClient.writeTxn(() async {
      await _isarClient.deadlines.delete(deleteID);
    });

    _deadlineCount = await getOnlineCount();
    notifyListeners();
  }

  // Search + Most Recent
  @override
  Future<List<Deadline>> search(
          {required String searchString, bool toDelete = false}) async =>
      await _isarClient.deadlines
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
  Future<List<Deadline>> mostRecent(
          {int limit = Constants.minLimitPerQuery}) async =>
      await _isarClient.deadlines
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
  Future<Deadline?> getByID({required int id}) async =>
      await _isarClient.deadlines.where().idEqualTo(id).findFirst();

  @override
  Future<bool> containsID({required int id}) async {
    List<Deadline> duplicates =
        await _isarClient.deadlines.where().idEqualTo(id).findAll();
    return duplicates.isNotEmpty;
  }

  @override
  Future<List<Deadline>> getRepoList(
          {int limit = Constants.minLimitPerQuery, int offset = 0}) async =>
      await _isarClient.deadlines
          .where()
          .toDeleteEqualTo(false)
          .filter()
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
  Future<List<Deadline>> getRepoListBy(
      {int limit = Constants.minLimitPerQuery,
      int offset = 0,
      required SortableView<Deadline> sorter}) async {
    switch (sorter.sortMethod) {
      case SortMethod.name:
        if (sorter.descending) {
          return await _isarClient.deadlines
              .where()
              .toDeleteEqualTo(false)
              .filter()
              .group((q) => q
                  .repeatableStateEqualTo(RepeatableState.normal)
                  .or()
                  .repeatableStateEqualTo(RepeatableState.delta))
              .sortByNameDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        } else {
          return await _isarClient.deadlines
              .where()
              .toDeleteEqualTo(false)
              .filter()
              .group((q) => q
                  .repeatableStateEqualTo(RepeatableState.normal)
                  .or()
                  .repeatableStateEqualTo(RepeatableState.delta))
              .sortByName()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
      case SortMethod.priority:
        if (sorter.descending) {
          return await _isarClient.deadlines
              .where()
              .toDeleteEqualTo(false)
              .filter()
              .group((q) => q
                  .repeatableStateEqualTo(RepeatableState.normal)
                  .or()
                  .repeatableStateEqualTo(RepeatableState.delta))
              .sortByPriorityDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        } else {
          return await _isarClient.deadlines
              .where()
              .toDeleteEqualTo(false)
              .filter()
              .group((q) => q
                  .repeatableStateEqualTo(RepeatableState.normal)
                  .or()
                  .repeatableStateEqualTo(RepeatableState.delta))
              .sortByPriority()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
      case SortMethod.due_date:
        if (sorter.descending) {
          return await _isarClient.deadlines
              .where()
              .toDeleteEqualTo(false)
              .filter()
              .group((q) => q
                  .repeatableStateEqualTo(RepeatableState.normal)
                  .or()
                  .repeatableStateEqualTo(RepeatableState.delta))
              .sortByDueDateDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        } else {
          return await _isarClient.deadlines
              .where()
              .toDeleteEqualTo(false)
              .filter()
              .group((q) => q
                  .repeatableStateEqualTo(RepeatableState.normal)
                  .or()
                  .repeatableStateEqualTo(RepeatableState.delta))
              .sortByDueDate()
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
  Future<List<Deadline>> getDeleted(
          {int limit = Constants.minLimitPerQuery, int offset = 0}) async =>
      await _isarClient.deadlines
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
  Future<List<Deadline>> getWarnMes(
          {DateTime? now, int limit = Constants.notificationLimit}) async =>
      await _isarClient.deadlines
          .where()
          .warnMeEqualTo(true)
          .filter()
          .toDeleteEqualTo(false)
          .group((q) => q
              .repeatableStateEqualTo(RepeatableState.normal)
              .or()
              .repeatableStateEqualTo(RepeatableState.delta))
          .dueDateGreaterThan(now ?? Constants.today)
          .sortByDueDate()
          .limit(limit)
          .findAll();

  @override
  Future<List<Deadline>> getRepeatables({DateTime? now}) async =>
      await _isarClient.deadlines
          .where()
          .repeatableEqualTo(true)
          .filter()
          .repeatableStateEqualTo(RepeatableState.normal)
          .originalStartLessThan(now ?? Constants.today)
          .findAll();

  @override
  Future<Deadline?> getNextRepeat(
          {required int repeatID, DateTime? now}) async =>
      await _isarClient.deadlines
          .where()
          .repeatableEqualTo(true)
          .filter()
          .repeatIDEqualTo(repeatID)
          .repeatableStateEqualTo(RepeatableState.normal)
          .originalStartLessThan(now ?? Constants.today)
          .findFirst();

  @override
  Future<Deadline?> getDelta(
          {required DateTime onDate, required int repeatID}) async =>
      await _isarClient.deadlines
          .where()
          .repeatableStateEqualTo(RepeatableState.delta)
          .filter()
          .originalStartEqualTo(onDate)
          .findFirst();

  @override
  Future<List<Deadline>> getDeltas(
          {DateTime? now, required int repeatID}) async =>
      await _isarClient.deadlines
          .where()
          .repeatableStateEqualTo(RepeatableState.delta)
          .filter()
          .repeatIDEqualTo(repeatID)
          .originalStartGreaterThan(now ?? Constants.today)
          .findAll();

  @override
  Future<Deadline?> getTemplate({required int repeatID}) async =>
      await _isarClient.deadlines
          .where()
          .repeatableStateEqualTo(RepeatableState.template)
          .filter()
          .repeatIDEqualTo(repeatID)
          .toDeleteEqualTo(false)
          .findFirst();

  Future<List<int>> getDeleteIDs({DateTime? deleteLimit}) async {
    deleteLimit = deleteLimit ?? Constants.today;
    return await _isarClient.deadlines
        .where()
        .toDeleteEqualTo(true)
        .filter()
        .lastUpdatedLessThan(deleteLimit)
        .idProperty()
        .findAll();
  }

  Future<List<Deadline>> getUnsynced() async =>
      await _isarClient.deadlines.where().isSyncedEqualTo(false).findAll();

  @override
  Future<List<Deadline>> getRange({DateTime? start, DateTime? end}) async {
    start = start ?? DateTime.now().copyWith(day: 1);
    end = end ?? start.copyWith(month: start.month + 1);
    return await _isarClient.deadlines
        .where()
        .dueDateBetween(start, end)
        .filter()
        .toDeleteEqualTo(false)
        .repeatableStateEqualTo(RepeatableState.normal)
        .findAll();
  }

  @override
  Future<List<Deadline>> getUpcoming(
          {int limit = Constants.minLimitPerQuery, int offset = 0}) async =>
      await _isarClient.deadlines
          .where()
          .dueDateGreaterThan(DateTime.now())
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

  @override
  Future<List<Deadline>> getOverdues(
          {int limit = Constants.minLimitPerQuery, int offset = 0}) async =>
      _isarClient.deadlines
          .where()
          .dueDateIsNotNull()
          .filter()
          .dueDateLessThan(DateTime.now())
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

  DeadlineRepo._internal();
}
