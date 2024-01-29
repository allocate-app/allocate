import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/task/reminder.dart';
import '../services/isar_service.dart';
import '../services/supabase_service.dart';
import '../util/constants.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/interfaces/repository/model/reminder_repository.dart';
import '../util/interfaces/sortable.dart';

class ReminderRepo extends ChangeNotifier implements ReminderRepository {
  static final ReminderRepo _instance = ReminderRepo._internal();

  static ReminderRepo get instance => _instance;
  final SupabaseClient _supabaseClient =
      SupabaseService.instance.supabaseClient;

  late final RealtimeChannel _reminderStream;

  final Isar _isarClient = IsarService.instance.isarClient;

  bool get isConnected => SupabaseService.instance.isConnected;

  int _reminderCount = 0;
  bool _subscribed = false;

  @override
  Future<Reminder> create(Reminder reminder) async {
    reminder.isSynced = isConnected;
    late int? id;

    await _isarClient.writeTxn(() async {
      id = await _isarClient.reminders.put(reminder);
    });
    if (null == id) {
      throw FailureToCreateException("Failed to create reminder locally\n"
          "Reminder: ${reminder.toString()}\n"
          "Time: ${DateTime.now()}\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (isConnected) {
      Map<String, dynamic> reminderEntity = reminder.toEntity();
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from("reminders")
          .insert(reminderEntity)
          .select("id");
      id = response.last["id"];
      if (null == id) {
        throw FailureToUploadException("Failed to sync reminder on create\n"
            "Reminder: ${reminder.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
    return reminder;
  }

  @override
  Future<Reminder> update(Reminder reminder) async {
    reminder.isSynced = isConnected;

    late int? id;
    await _isarClient.writeTxn(() async {
      id = await _isarClient.reminders.put(reminder);
    });

    if (null == id) {
      throw FailureToUpdateException("Failed to update reminder locally\n"
          "Reminder: ${reminder.toString()}\n"
          "Time: ${DateTime.now()}\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (isConnected) {
      Map<String, dynamic> reminderEntity = reminder.toEntity();
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from("reminders")
          .update(reminderEntity)
          .select("id");

      id = response.last["id"];

      if (null == id) {
        throw FailureToUploadException("Failed to sync reminder on update\n"
            "Reminder: ${reminder.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
    return reminder;
  }

  @override
  Future<void> updateBatch(List<Reminder> reminders) async {
    late List<int?> ids;
    late int? id;
    await _isarClient.writeTxn(() async {
      ids = List<int?>.empty(growable: true);
      for (Reminder reminder in reminders) {
        reminder.isSynced = isConnected;
        id = await _isarClient.reminders.put(reminder);
        ids.add(id);
      }
    });
    if (ids.any((id) => null == id)) {
      throw FailureToUpdateException("Failed to update reminders locally\n"
          "Reminders: ${reminders.toString()}\n"
          "Time: ${DateTime.now()}\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (isConnected) {
      ids.clear();
      List<Map<String, dynamic>> reminderEntities =
          reminders.map((reminder) => reminder.toEntity()).toList();
      final List<Map<String, dynamic>> responses = await _supabaseClient
          .from("reminders")
          .upsert(reminderEntities)
          .select("id");

      ids = responses.map((response) => response["id"] as int?).toList();

      if (ids.any((id) => null == id)) {
        throw FailureToUploadException("Failed to sync reminders on update \n"
            "Reminder: ${reminders.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
  }

  @override
  Future<void> delete(Reminder reminder) async {
    reminder.toDelete = true;
    await update(reminder);
  }

  @override
  Future<void> remove(Reminder reminder) async {
    // Delete online
    if (isConnected) {
      try {
        await _supabaseClient.from("reminders").delete().eq("id", reminder.id);
      } catch (error) {
        throw FailureToDeleteException("Failed to delete Reminder online\n"
            "Reminder: ${reminder.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
    // Delete local
    await _isarClient.writeTxn(() async {
      await _isarClient.reminders.delete(reminder.id);
    });
  }

  @override
  Future<List<int>> emptyTrash() async {
    if (isConnected) {
      try {
        await _supabaseClient.from("reminders").delete().eq("toDelete", true);
      } catch (error) {
        throw FailureToDeleteException("Failed to empty trash online\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
    late List<int> deleteIDs;
    await _isarClient.writeTxn(() async {
      deleteIDs = await _isarClient.reminders
          .where()
          .toDeleteEqualTo(true)
          .idProperty()
          .findAll();
      await _isarClient.reminders.deleteAll(deleteIDs);
    });
    return deleteIDs;
  }

  @override
  Future<void> clearDB() async {
    if (isConnected) {
      // not sure whether or not to catch errors.
      await _supabaseClient
          .from("reminders")
          .delete()
          .neq("customViewIndex", -2);
    }

    await _isarClient.writeTxn(() async {
      await _isarClient.reminders.clear();
    });
  }

  @override
  Future<List<int>> deleteFutures({required Reminder deleteFrom}) async {
    List<int> toDelete = await _isarClient.reminders
        .where()
        .repeatIDEqualTo(deleteFrom.repeatID)
        .filter()
        .dueDateGreaterThan(deleteFrom.dueDate!)
        .idProperty()
        .findAll();

    // Online
    if (isConnected) {
      try {
        await _supabaseClient
            .from("reminders")
            .delete()
            .inFilter("id", toDelete);
      } catch (error) {
        throw FailureToDeleteException(
            "Failed to delete future events online \n"
            "Reminder: ${deleteFrom.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }

    // Offline
    await _isarClient.writeTxn(() async {
      await _isarClient.reminders.deleteAll(toDelete);
    });

    return toDelete;
  }

  @override
  Future<void> deleteSweep({DateTime? upTo}) async {
    List<int> toDeletes = await getDeleteIDs(deleteLimit: upTo);

    if (isConnected) {
      try {
        await _supabaseClient
            .from("reminders")
            .delete()
            .inFilter("id", toDeletes);
      } catch (error) {
        throw FailureToDeleteException("Failed to delete reminders online \n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
    await _isarClient.writeTxn(() async {
      await _isarClient.reminders.deleteAll(toDeletes);
    });
  }

  Future<int> getOnlineCount() async =>
      _supabaseClient.from("reminders").count(CountOption.exact);

  @override
  Future<void> syncRepo() async {
    if (!isConnected) {
      return;
    }

    // Get the set of unsynced data.
    Set<Reminder> unsynced = await getUnsynced().then((_) => _.toSet());

    // Get the online count.
    _reminderCount = await getOnlineCount();

    // Fetch new data -> by fetchRepo();
    List<Reminder> onlineReminders = await fetchRepo();

    List<Reminder> toInsert = List.empty(growable: true);
    for (Reminder reminder in onlineReminders) {
      Reminder? otherReminder = unsynced.lookup(reminder);
      // Prioritize by last updated -> unsynced data will overwrite new data.
      if (null != otherReminder &&
          reminder.lastUpdated.isAfter(otherReminder.lastUpdated)) {
        unsynced.remove(otherReminder);
      }
      toInsert.add(reminder);
    }

    // Put all new data in the db.
    await _isarClient.writeTxn(() async {
      await _isarClient.reminders.putAll(toInsert);
    });

    // Update the unsynced data.
    await updateBatch(unsynced.toList());

    if (onlineReminders.length < _reminderCount) {
      // Give the db a moment to refresh.
      await Future.delayed(const Duration(seconds: 1));
      insertRemaining(totalFetched: onlineReminders.length).whenComplete(() {
        notifyListeners();
      });
    }

    notifyListeners();
  }

  Future<void> insertRemaining({required int totalFetched}) async {
    List<Reminder> toInsert = List.empty(growable: true);
    while (totalFetched < _reminderCount) {
      List<Reminder>? newReminders = await fetchRepo(offset: totalFetched);

      // If there is no data or connection is lost, break.
      if (newReminders.isEmpty) {
        break;
      }
      toInsert.addAll(newReminders);
      totalFetched += newReminders.length;
    }

    await _isarClient.writeTxn(() async {
      await _isarClient.reminders.putAll(toInsert);
    });
  }

  @override
  Future<List<Reminder>> fetchRepo({int limit = 1000, int offset = 0}) async {
    List<Reminder> data = List.empty(growable: true);
    if (!isConnected) {
      return data;
    }
    List<Map<String, dynamic>> reminderEntities = await _supabaseClient
        .from("reminders")
        .select()
        .order("lastUpdated", ascending: false)
        .range(offset, offset + limit);

    for (Map<String, dynamic> entity in reminderEntities) {
      data.add(Reminder.fromEntity(entity: entity));
    }
    return data;
  }

  Future<void> handleUpsert(PostgresChangePayload payload) async {
    Reminder reminder = Reminder.fromEntity(entity: payload.newRecord);
    await _isarClient.writeTxn(() async {
      await _isarClient.reminders.put(reminder);
    });

    _reminderCount = await getOnlineCount();
  }

  Future<void> handleDelete(PostgresChangePayload payload) async {
    int deleteID = payload.oldRecord["id"] as int;
    await _isarClient.writeTxn(() async {
      await _isarClient.reminders.delete(deleteID);
    });

    _reminderCount = await getOnlineCount();
  }

  @override
  Future<List<Reminder>> search(
          {required String searchString, bool toDelete = false}) async =>
      await _isarClient.reminders
          .where()
          .toDeleteEqualTo(toDelete)
          .filter()
          .group((q) => q
              .repeatableStateEqualTo(RepeatableState.normal)
              .or()
              .repeatableStateEqualTo(RepeatableState.delta))
          .nameContains(searchString, caseSensitive: false)
          .limit(5)
          .findAll();

  @override
  Future<List<Reminder>> mostRecent(
          {int limit = Constants.minLimitPerQuery}) async =>
      await _isarClient.reminders
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
  Future<Reminder?> getByID({required int id}) async =>
      await _isarClient.reminders.where().idEqualTo(id).findFirst();

  @override
  Future<List<Reminder>> getRepoList(
          {int limit = Constants.minLimitPerQuery, int offset = 0}) async =>
      await _isarClient.reminders
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
  Future<List<Reminder>> getRepoListBy(
      {int limit = Constants.minLimitPerQuery,
      int offset = 0,
      required SortableView<Reminder> sorter}) async {
    switch (sorter.sortMethod) {
      case SortMethod.name:
        if (sorter.descending) {
          return await _isarClient.reminders
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
          return await _isarClient.reminders
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
        }
      case SortMethod.due_date:
        if (sorter.descending) {
          return await _isarClient.reminders
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
          return await _isarClient.reminders
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
  Future<List<Reminder>> getDeleted(
          {int limit = Constants.minLimitPerQuery, int offset = 0}) async =>
      await _isarClient.reminders
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
  Future<List<Reminder>> getWarnMes(
          {DateTime? now, int limit = Constants.notificationLimit}) async =>
      await _isarClient.reminders
          .where()
          .dueDateGreaterThan(now ?? Constants.today)
          .filter()
          .toDeleteEqualTo(false)
          .group((q) => q
              .repeatableStateEqualTo(RepeatableState.normal)
              .or()
              .repeatableStateEqualTo(RepeatableState.delta))
          .sortByDueDate()
          .limit(limit)
          .findAll();

  // Needs to be able to pick up deleted bc delta
  @override
  Future<List<Reminder>> getRepeatables({DateTime? now}) async =>
      await _isarClient.reminders
          .where()
          .repeatableEqualTo(true)
          .filter()
          .repeatableStateEqualTo(RepeatableState.normal)
          .originalDueLessThan(now ?? Constants.today)
          .findAll();

  @override
  Future<Reminder?> getNextRepeat(
          {required int repeatID, DateTime? now}) async =>
      await _isarClient.reminders
          .where()
          .repeatableEqualTo(true)
          .filter()
          .repeatIDEqualTo(repeatID)
          .repeatableStateEqualTo(RepeatableState.normal)
          .originalDueLessThan(now ?? Constants.today)
          .findFirst();

  @override
  Future<Reminder?> getDelta(
          {required DateTime onDate, required int repeatID}) async =>
      await _isarClient.reminders
          .where()
          .repeatableStateEqualTo(RepeatableState.delta)
          .filter()
          .originalDueEqualTo(onDate)
          .findFirst();

  @override
  Future<List<Reminder>> getDeltas(
          {DateTime? now, required int repeatID}) async =>
      await _isarClient.reminders
          .where()
          .repeatableStateEqualTo(RepeatableState.delta)
          .filter()
          .repeatIDEqualTo(repeatID)
          .originalDueGreaterThan(now ?? Constants.today)
          .findAll();

  @override
  Future<Reminder?> getTemplate({required int repeatID}) async =>
      await _isarClient.reminders
          .where()
          .repeatableStateEqualTo(RepeatableState.template)
          .filter()
          .repeatIDEqualTo(repeatID)
          .toDeleteEqualTo(false)
          .findFirst();

  Future<List<int>> getDeleteIDs({DateTime? deleteLimit}) async {
    deleteLimit = deleteLimit ?? Constants.today;
    return await _isarClient.reminders
        .where()
        .toDeleteEqualTo(true)
        .filter()
        .lastUpdatedLessThan(deleteLimit)
        .idProperty()
        .findAll();
  }

  Future<List<Reminder>> getUnsynced() async =>
      await _isarClient.reminders.where().isSyncedEqualTo(false).findAll();

  @override
  Future<List<Reminder>> getRange({DateTime? start, DateTime? end}) async {
    start = start ?? DateTime.now().copyWith(day: 1);
    end = end ?? start.copyWith(month: start.month + 1);
    return await _isarClient.reminders
        .where()
        .dueDateBetween(start, end)
        .filter()
        .toDeleteEqualTo(false)
        .repeatableStateEqualTo(RepeatableState.normal)
        .findAll();
  }

  @override
  Future<List<Reminder>> getUpcoming(
          {int limit = Constants.minLimitPerQuery, int offset = 0}) async =>
      await _isarClient.reminders
          .where()
          .dueDateGreaterThan(Constants.today)
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
  Future<List<Reminder>> getOverdues(
          {int limit = Constants.minLimitPerQuery, int offset = 0}) async =>
      await _isarClient.reminders
          .where()
          .dueDateLessThan(Constants.today)
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

  ReminderRepo._internal() {
    // I haven't faked the connection channels -> doesn't make sense to.
    if (SupabaseService.instance.offlineDebug) {
      return;
    }
    // Initialize table stream -> only listen on signIn.
    _reminderStream = _supabaseClient
        .channel("public:reminders")
        .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: "public",
            table: "reminders",
            callback: handleUpsert)
        .onPostgresChanges(
            schema: "public",
            table: "reminders",
            event: PostgresChangeEvent.update,
            callback: handleUpsert)
        .onPostgresChanges(
            schema: "public",
            table: "reminders",
            event: PostgresChangeEvent.delete,
            callback: handleDelete);

    // Listen to auth changes.
    SupabaseService.instance.authSubscription.listen((AuthState data) async {
      final AuthChangeEvent event = data.event;
      switch (event) {
        case AuthChangeEvent.signedIn:
          await syncRepo();
          // OPEN TABLE STREAM -> insert new data.
          if (!_subscribed) {
            _reminderStream.subscribe();
            _subscribed = true;
          }
          break;
        case AuthChangeEvent.tokenRefreshed:
          if (!_subscribed) {
            await syncRepo();
            _reminderStream.subscribe();
            _subscribed = true;
          }
          break;
        case AuthChangeEvent.signedOut:
          // CLOSE TABLE STREAM.
          await _reminderStream.unsubscribe();
          _subscribed = false;
          break;
        default:
          break;
      }
      // if (event == AuthChangeEvent.signedIn) {
      //   await syncRepo();
      //   // OPEN TABLE STREAM -> insert new data.
      //   if (!_subscribed) {
      //     _reminderStream.subscribe();
      //     _subscribed = true;
      //   }
      //   return;
      // }
      // if (event == AuthChangeEvent.tokenRefreshed) {
      //   // If not listening to the stream, there hasn't been an update.
      //   // Sync accordingly.
      //   if (!_subscribed) {
      //     await syncRepo();
      //     _reminderStream.subscribe();
      //     _subscribed = true;
      //   }
      //   return;
      // }
      // if (event == AuthChangeEvent.signedOut) {
      //   // CLOSE TABLE STREAM.
      //   await _reminderStream.unsubscribe();
      //   _subscribed = false;
      // }
    });
  }
}
