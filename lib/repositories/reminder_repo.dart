import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/task/reminder.dart';
import '../services/isar_service.dart';
import '../services/supabase_service.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/interfaces/repository/reminder_repository.dart';
import '../util/interfaces/sortable.dart';

class ReminderRepo implements ReminderRepository {
  ReminderRepo();

  final SupabaseClient _supabaseClient = SupabaseService.supabaseClient;
  final Isar _isarClient = IsarService.isarClient;

  // This may be best moved to the service, or update this value via the service.
  DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));

  @override
  Future<void> create(Reminder reminder) async {
    reminder.isSynced = (null != _supabaseClient.auth.currentSession);
    late int? id;

    await _isarClient.writeTxn(() async {
      id = await _isarClient.reminders.put(reminder);
    });
    if (null == id) {
      throw FailureToCreateException("Failed to create reminder locally");
    }

    reminder.id = id!;

    if (null != _supabaseClient.auth.currentSession) {
      Map<String, dynamic> reminderEntity = reminder.toEntity();
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from("reminders")
          .insert(reminderEntity)
          .select("id");
      id = response.last["id"];
      if (null == id) {
        throw FailureToUploadException("Failed to sync reminder on create");
      }
    }
  }

  @override
  Future<void> update(Reminder reminder) async {
    reminder.isSynced = (null != _supabaseClient.auth.currentSession);

    late int? id;
    await _isarClient.writeTxn(() async {
      id = await _isarClient.reminders.put(reminder);
    });

    if (null == id) {
      throw FailureToUpdateException("Failed to update deadline locally");
    }

    if (null != _supabaseClient.auth.currentSession) {
      Map<String, dynamic> reminderEntity = reminder.toEntity();
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from("reminders")
          .update(reminderEntity)
          .select("id");

      id = response.last["id"];

      if (null == id) {
        throw FailureToUploadException("Failed to sync deadline on update");
      }
    }
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
      throw FailureToUpdateException("Failed to update reminders locally");
    }

    if (null != _supabaseClient.auth.currentSession) {
      ids.clear();
      List<Map<String, dynamic>> reminderEntities =
          reminders.map((reminder) => reminder.toEntity()).toList();
      for (Map<String, dynamic> reminderEntity in reminderEntities) {
        final List<Map<String, dynamic>> response = await _supabaseClient
            .from("reminders")
            .update(reminderEntity)
            .select("id");
        id = response.last["id"];
        ids.add(id);
      }
      if (ids.any((id) => null == id)) {
        throw FailureToUploadException("Failed to sync reminders on update");
      }
    }
  }

  @override
  Future<void> delete(Reminder reminder) async {
    if (null != _supabaseClient.auth.currentSession) {
      reminder.toDelete = true;
      update(reminder);
      return;
    }

    try {
      await _supabaseClient.from("reminders").delete().eq("id", reminder.id);
    } catch (error) {
      throw FailureToDeleteException("Failed to delete reminder online");
    }
  }

  @override
  Future<void> deleteLocal() async {
    List<int> toDeletes = await getDeleteIds();
    await _isarClient.writeTxn(() async {
      await _isarClient.reminders.deleteAll(toDeletes);
    });
  }

  @override
  Future<void> syncRepo({bool showLoading = true}) async {
    // Get the non-deleted stuff from Isar
    List<int> toDeletes = await getDeleteIds();
    if (toDeletes.isEmpty) {
      return fetchRepo();
    }

    try {
      await _supabaseClient.from("reminders").delete().in_("id", toDeletes);
    } catch (error) {
      // I'm also unsure about this Exception.
      throw FailureToDeleteException("Failed to delete reminders on sync");
    }

    // Get the non-uploaded stuff from Isar.
    List<Reminder> unsyncedReminders = await getUnsynced();

    if (unsyncedReminders.isEmpty) {
      return fetchRepo();
    }

    List<Map<String, dynamic>> syncEntities = unsyncedReminders.map((reminder) {
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
      throw FailureToUploadException("Failed to sync reminders");
    }

    // Fetch from supabase.
    fetchRepo();
  }

  @override
  Future<void> fetchRepo() async {
    // This needs refactoring to work with a loading widget -> Factor into provider.
    // showLoading ? startLoading() : null;
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
  Future<Reminder?> getByID({required int id}) async =>
      await _isarClient.reminders.where().idEqualTo(id).findFirst();

  @override
  Future<List<Reminder>> getRepoList() => _isarClient.reminders
      .where()
      .dueDateGreaterThan(yesterday)
      .filter()
      .toDeleteEqualTo(false)
      .sortByCustomViewIndex()
      .findAll();

  @override
  Future<List<Reminder>> getRepoListBy(
      {bool showLoading = true, required SortableView<Reminder> sorter}) async {
    switch (sorter.sortMethod) {
      case SortMethod.name:
        if (sorter.descending) {
          return _isarClient.reminders
              .where()
              .dueDateGreaterThan(yesterday)
              .filter()
              .toDeleteEqualTo(false)
              .sortByNameDesc()
              .findAll();
        } else {
          return _isarClient.reminders
              .where()
              .dueDateGreaterThan(yesterday)
              .filter()
              .toDeleteEqualTo(false)
              .sortByNameDesc()
              .findAll();
        }
      case SortMethod.dueDate:
        if (sorter.descending) {
          return _isarClient.reminders
              .where()
              .dueDateGreaterThan(yesterday)
              .filter()
              .toDeleteEqualTo(false)
              .sortByDueDateDesc()
              .findAll();
        } else {
          return _isarClient.reminders
              .where()
              .dueDateGreaterThan(yesterday)
              .filter()
              .toDeleteEqualTo(false)
              .sortByDueDate()
              .findAll();
        }
      default:
        return getRepoList();
    }
  }

  Future<List<int>> getDeleteIds() async => _isarClient.reminders
      .where()
      .toDeleteEqualTo(true)
      .idProperty()
      .findAll();
  Future<List<Reminder>> getUnsynced() async =>
      _isarClient.reminders.where().isSyncedEqualTo(false).findAll();
}
