import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/isar_service.dart';
import '../services/supabase_service.dart';

import '../model/task/reminder.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/interfaces/reminder_repository.dart';

class ReminderRepo implements ReminderRepository
{
  // Not sure whether to singleton.
  static final ReminderRepo _instance = ReminderRepo._internal();
  static ReminderRepo get instance => _instance;

  final SupabaseClient _supabaseClient = SupabaseService.supabaseClient;
  final Isar _isarClient = IsarService.isarClient;

  // This may be best moved to the service, or update this value via the service.
  DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));

  @override
  Future<void> create(Reminder r) async {
    r.isSynced = isDeviceConnected.value;
    late int? id;

    await _isarClient.writeTxn(() async {
      id = await _isarClient.reminders.put(r);
    });

    if(null == id)
    {
      throw FailureToCreateException("Failed to create deadline locally");
    }

    if(isDeviceConnected.value)
    {
      Map<String, dynamic> reminderEntity = d.toEntity();
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from("reminders")
          .insert(routineEntity)
          .select("id");
      id = response.last["id"];
      if(null == id)
      {
        throw FailureToUploadException("Failed to sync deadline on create");
      }
    }
  }
  @override
  Future<void> update(Reminder r) async {
    r.isSynced = isDeviceConnected.value;

    late int? id;
    await _isarClient.writeTxn(() async {
      id = await _isarClient.reminders.put(r);
    });

    if(null == id)
    {
      throw FailureToUpdateException("Failed to update deadline locally");
    }

    if(isDeviceConnected.value)
    {
      Map<String, dynamic> reminderEntity = r.toEntity();
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from("reminders")
          .update(reminderEntity)
          .select("id");

      id = response.last["id"];

      if(null == id)
      {
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
      for(Reminder r in reminders)
      {
        r.isSynced = isDevice.Connected.value;
        id = await _isarClient.reminders.put(r);
        ids.add(id);
      }
    });
    if(ids.any((id) => null == id))
    {
      throw FailureToUpdateException("Failed to update reminders locally");
    }

    if(isDevice.Connected.value)
    {
      ids.clear();
      List<Map<String, dynamic>> reminderEntities= reminders.map((r) => r.toEntity()).toList();
      for(Map<String, dynamic> reminderEntity in reminderEntities)
      {
        final List<Map<String, dynamic>> response = await _supabaseClient
            .from("reminders")
            .update(reminderEntity)
            .select("id");
        id = response.last["id"];
        ids.add(id);
      }
      if(ids.any((id) => null == id))
      {
        throw FailureToUploadException("Failed to sync reminders on update");
      }
    }

  }

  @override
  Future<void> retry(List<Reminder> reminders) async {
    late List<int?> ids;
    late int? id;

    await _isarClient.writeTxn(() async {
      ids = List<int?>.empty(growable: true);
      for(Reminder r in reminders)
      {
        r.isSynced = isDevice.Connected.value;
        id = await _isarClient.reminders.put(r);
        ids.add(id);
      }
    });
    if(ids.any((id) => null == id))
    {
      throw FailureToUpdateException("Failed to update routines locally");
    }

    // TODO: Tweak this logic. Can send the entities directly for upsert.
    // Can also grab the ids & flatten.
    if(isDevice.Connected.value)
    {
      ids.clear();
      List<Map<String, dynamic>> reminderEntities= reminders.map((d) => d.toEntity()).toList();
      for(Map<String, dynamic> reminderEntity in reminderEntities)
      {
        final List<Map<String, dynamic>> response = await _supabaseClient
            .from("reminders")
            .upsert(reminderEntity)
            .select("id");
        id = response.last["id"];
        ids.add(id);
      }
      if(ids.any((id) => null == id))
      {
        throw FailureToUploadException("Failed to sync reminders on update");
      }
    }
  }

  @override
  Future<void> delete(Reminder r) async {
    try
    {
      await _supabaseClient
          .from("reminders")
          .delete()
          .eq("id", r.id);

      await _isarClient.writeTxn(() async {
        await _isarClient.reminders.delete(r.id);
      }
      );
    }
    catch(error){
      throw FailureToDeleteException("Failed to delete deadline");
    }
  }

  @override
  Future<void> syncRepo({bool showLoading = true}) async {
    // Get the non-deleted stuff from Isar
    List<int> toDeletes = await getDeleteIds();
    if(toDeletes.isNotEmpty)
    {
      try{
        await _supabaseClient
            .from("reminders")
            .delete()
            .in_("id", toDeletes);

        await _isarClient.writeTxn(() async {
          // Not sure if I want to store this -> returns a boolean for successful deletion.
          await _isarClient.reminders.deleteAll(toDeletes);
        });
      }
      catch(error) {
        // I'm also unsure about this Exception.
        throw FailureToDeleteException("Failed to delete reminders");
      }
    }


    // Get the non-uploaded stuff from Isar.
    List<Reminder> unsyncedRoutines = await getUnsynced();

    if(unsyncedRoutines.isNotEmpty) {
      List<Map<String, dynamic>> syncEntities = unsyncedRoutines.map((d){d.isSynced = true;return d.toEntity();}).toList();

      final List<Map<String, dynamic>> responses = await _supabaseClient
          .from("reminders")
          .upsert(syncEntities)
          .select("id");

      List<int?> ids = responses.map((response) => response["id"] as int?).toList();

      if(ids.any((id) => null == id))
      {
        // Any unsynced stuff will just be caught on next sync.
        // This may not need to be a thing to handle.
        throw FailureToUploadException("Failed to Sync reminders");
      }
    }
    fetchRepo(showLoading: false);
  }
  @override
  Future<void> fetchRepo({bool showLoading = true}) async {
    late List<Map<String, dynamic>> reminderEntities;

    await Future.delayed(const Duration(seconds: 1)).then((value) async
    {
      if(!isDeviceConnected.value)
      {
        return;
      }
      reminderEntities = await _supabaseClient
          .from("reminders")
          .select();

      if(reminderEntities.isEmpty)
      {
        return;
      }

      List<Reminder> reminders = reminderEntities.map((r) => Reminder.fromEntity(entity: r)).toList();
      await _isarClient.writeTxn(() async {
        await _isarClient.clear();
        for(Reminder r in reminders)
        {
          _isarClient.reminders.put(r);
        }
      });
    });
  }

  // Custom view position, reorderable list.
  // CHECK THIS and put in proper query logic pls.
  // POSSIBLY PUT A HARD LIMIT?
  @override
  Future<List<Reminder>> getRepoList({bool showLoading = true}) => _isarClient.reminders.filter().dueDateGreaterThan(yesterday).findAll();

  @override
  Future<List<Reminder>> getRepoListBy({bool showLoading = true, Sorter<Reminder> sorter}) async {
    switch(sorter.sortMethod)
    {
    //TODO: query logic.
      case SortMethod.name:
        if(sorter.descending)
        {
          return _isarClient.reminders.filter().dueDateGreaterThan(yesterday).findAll();
        }
        else
        {
          return _isarClient.reminders.filter().dueDateGreaterThan(yesterday).findAll();
        }
      case SortMethod.priority:
        if(sorter.descending)
        {
          return _isarClient.reminders.filter().dueDateGreaterThan(yesterday).findAll();
        }
        else
        {
          return _isarClient.reminders.filter().dueDateGreaterThan(yesterday).findAll();
        }
      case SortMethod.dueDate:
        if(sorter.descending)
        {
          return _isarClient.reminders.filter().dueDateGreaterThan(yesterday).findAll();
        }
        else
        {
          return _isarClient.reminders.filter().dueDateGreaterThan(yesterday).findAll();
        }
      default:
        return getRepoList(showLoading: false);
    }
  }

  Future<List<int>> getDeleteIds() async => _isarClient.reminders.filter().toDeleteEqualTo(true).idProperty.findAll();
  Future<List<Reminder>> getUnsynced() async => _isarClient.reminders.filter().isSyncedEqualTo(false).findAll();

  ReminderRepo._internal();
  
}