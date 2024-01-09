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

class ReminderRepo implements ReminderRepository {
  static final ReminderRepo _instance = ReminderRepo._internal();

  static ReminderRepo get instance => _instance;
  final SupabaseClient _supabaseClient =
      SupabaseService.instance.supabaseClient;
  final Isar _isarClient = IsarService.instance.isarClient;

  @override
  Future<Reminder> create(Reminder reminder) async {
    reminder.isSynced = (null != _supabaseClient.auth.currentSession);
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

    if (null != _supabaseClient.auth.currentSession) {
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
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }
    return reminder;
  }

  @override
  Future<Reminder> update(Reminder reminder) async {
    reminder.isSynced = (null != _supabaseClient.auth.currentSession);

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

    if (null != _supabaseClient.auth.currentSession) {
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
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
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
        reminder.isSynced = (null != _supabaseClient.auth.currentSession);
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

    if (null != _supabaseClient.auth.currentSession) {
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
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
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
    if (null != _supabaseClient.auth.currentSession) {
      try {
        await _supabaseClient.from("reminders").delete().eq("id", reminder.id);
      } catch (error) {
        throw FailureToDeleteException("Failed to delete Reminder online\n"
            "Reminder: ${reminder.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }
    // Delete local
    await _isarClient.writeTxn(() async {
      await _isarClient.reminders.delete(reminder.id);
    });
  }

  @override
  Future<List<int>> emptyTrash() async {
    if (null != _supabaseClient.auth.currentSession) {
      try {
        await _supabaseClient.from("reminders").delete().eq("toDelete", true);
      } catch (error) {
        throw FailureToDeleteException("Failed to empty trash online\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
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
  Future<List<int>> deleteFutures({required Reminder deleteFrom}) async {
    List<int> toDelete = await _isarClient.reminders
        .where()
        .repeatIDEqualTo(deleteFrom.repeatID)
        .filter()
        .dueDateGreaterThan(deleteFrom.dueDate!)
        .idProperty()
        .findAll();

    // Online
    if (null != _supabaseClient.auth.currentSession) {
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
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }

    // Offline
    await _isarClient.writeTxn(() async {
      await _isarClient.reminders.deleteAll(toDelete);
    });

    return toDelete;
  }

  @override
  Future<void> deleteSweep() async {
    List<int> toDeletes = await getDeleteIDs();
    await _isarClient.writeTxn(() async {
      await _isarClient.reminders.deleteAll(toDeletes);
    });
  }

  @override
  Future<void> syncRepo() async {
    if (null == _supabaseClient.auth.currentSession) {
      return fetchRepo();
    }

    List<int> toDeletes = await getDeleteIDs();
    if (toDeletes.isNotEmpty) {
      try {
        await _supabaseClient
            .from("reminders")
            .delete()
            .inFilter("id", toDeletes);
      } catch (error) {
        // I'm also unsure about this Exception.
        throw FailureToDeleteException("Failed to delete reminders on sync\n"
            "ids: ${toDeletes.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }

    // Get the non-uploaded stuff from Isar.
    List<Reminder> unsyncedReminders = await getUnsynced();

    if (unsyncedReminders.isNotEmpty) {
      List<Map<String, dynamic>> syncEntities =
          unsyncedReminders.map((reminder) {
        reminder.isSynced = true;
        return reminder.toEntity();
      }).toList();

      final List<Map<String, dynamic>> responses = await _supabaseClient
          .from("reminders")
          .upsert(syncEntities)
          .select("id");

      List<int?> ids =
          responses.map((response) => response["id"] as int?).toList();

      if (ids.any((id) => null == id)) {
        throw FailureToUploadException("Failed to sync reminders\n"
            "Reminders: ${unsyncedReminders.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }

    // Fetch from supabase.
    fetchRepo();
  }

  @override
  Future<void> fetchRepo() async {
    late List<Map<String, dynamic>> reminderEntities;

    await Future.delayed(const Duration(seconds: 1)).then((value) async {
      if (null == _supabaseClient.auth.currentSession) {
        return;
      }
      reminderEntities = await _supabaseClient.from("reminders").select();

      if (reminderEntities.isEmpty) {
        return;
      }

      List<Reminder> reminders = reminderEntities
          .map((reminder) => Reminder.fromEntity(entity: reminder))
          .toList();
      await _isarClient.writeTxn(() async {
        await _isarClient.reminders.clear();
        for (Reminder reminder in reminders) {
          _isarClient.reminders.put(reminder);
        }
      });
    });
  }

  @override
  Future<List<Reminder>> search(
          {required String searchString, bool toDelete = false}) async =>
      await _isarClient.reminders
          .where()
          .toDeleteEqualTo(toDelete)
          .filter()
          .nameContains(searchString, caseSensitive: false)
          .limit(5)
          .findAll();

  @override
  Future<List<Reminder>> mostRecent({int limit = 50}) async =>
      await _isarClient.reminders
          .where()
          .sortByLastUpdatedDesc()
          .limit(limit)
          .findAll();

  @override
  Future<Reminder?> getByID({required int id}) async =>
      await _isarClient.reminders.where().idEqualTo(id).findFirst();

  @override
  Future<List<Reminder>> getRepoList({int limit = 50, int offset = 0}) async =>
      await _isarClient.reminders
          .where()
          .toDeleteEqualTo(false)
          .filter()
          .repeatableStateEqualTo(RepeatableState.normal)
          .sortByCustomViewIndex()
          .thenByLastUpdatedDesc()
          .offset(offset)
          .limit(limit)
          .findAll();

  @override
  Future<List<Reminder>> getRepoListBy(
      {int limit = 50,
      int offset = 0,
      required SortableView<Reminder> sorter}) async {
    switch (sorter.sortMethod) {
      case SortMethod.name:
        if (sorter.descending) {
          return await _isarClient.reminders
              .where()
              .toDeleteEqualTo(false)
              .filter()
              .repeatableStateEqualTo(RepeatableState.normal)
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
              .repeatableStateEqualTo(RepeatableState.normal)
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
              .repeatableStateEqualTo(RepeatableState.normal)
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
              .repeatableStateEqualTo(RepeatableState.normal)
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
  Future<List<Reminder>> getDeleted({int limit = 50, int offset = 0}) async =>
      await _isarClient.reminders
          .where()
          .toDeleteEqualTo(true)
          .filter()
          .repeatableStateEqualTo(RepeatableState.normal)
          .sortByLastUpdatedDesc()
          .offset(offset)
          .limit(limit)
          .findAll();

  @override
  Future<List<Reminder>> getWarnMes({DateTime? now, int limit = 10}) async =>
      await _isarClient.reminders
          .where()
          .dueDateGreaterThan(now ?? Constants.today)
          .filter()
          .toDeleteEqualTo(false)
          .repeatableStateEqualTo(RepeatableState.normal)
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
  Future<Reminder?> getDelta(
          {required DateTime onDate, required int repeatID}) async =>
      await _isarClient.reminders
          .where()
          .repeatableStateEqualTo(RepeatableState.delta)
          .filter()
          .originalDueEqualTo(onDate)
          .findFirst();

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
  Future<List<Reminder>> getUpcoming({int limit = 50, int offset = 0}) async =>
      await _isarClient.reminders
          .where()
          .dueDateGreaterThan(Constants.today)
          .filter()
          .toDeleteEqualTo(false)
          .repeatableStateEqualTo(RepeatableState.normal)
          .sortByDueDate()
          .thenByLastUpdatedDesc()
          .offset(offset)
          .limit(limit)
          .findAll();

  @override
  Future<List<Reminder>> getOverdues({int limit = 50, int offset = 0}) async =>
      await _isarClient.reminders
          .where()
          .dueDateLessThan(Constants.today)
          .filter()
          .toDeleteEqualTo(false)
          .repeatableStateEqualTo(RepeatableState.normal)
          .sortByDueDateDesc()
          .thenByLastUpdatedDesc()
          .offset(offset)
          .limit(limit)
          .findAll();

  ReminderRepo._internal();
}
