import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/isar_service.dart';
import '../model/task/deadline.dart';
import '../services/supabase_service.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/interfaces/deadline_repository.dart';

class DeadLineRepo implements DeadLineRepository
{
  // Not sure whether to singleton.
  static final DeadLineRepo _instance = DeadLineRepo._internal();
  static DeadLineRepo get instance => _instance;

  final SupabaseClient _supabaseClient = SupabaseService.supabaseClient;
  final Isar _isarClient = IsarService.isarClient;

  // This may be best moved to the service, or update this value via the service.
  DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));

  @override
  Future<void> create(DeadLine d) async {
    d.isSynced = isDeviceConnected.value;
    late int? id;

    await _isarClient.writeTxn(() async {
      id = await _isarClient.deadlines.put(d);
    });

    if(null == id)
      {
        throw FailureToCreateException("Failed to create deadline locally");
      }

    if(isDeviceConnected.value)
      {
        Map<String, dynamic> deadlineEntity = d.toEntity();
        final List<Map<String, dynamic>> response = await _supabaseClient
            .from("deadlines")
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
  Future<void> update(DeadLine d) async {
    d.isSynced = isDeviceConnected.value;

    late int? id;
    await _isarClient.writeTxn(() async {
      id = await _isarClient.deadlines.put(d);
    });

    if(null == id)
      {
        throw FailureToUpdateException("Failed to update deadline locally");
      }

    if(isDeviceConnected.value)
      {
        Map<String, dynamic> deadlineEntity = d.toEntity();
        final List<Map<String, dynamic>> response = await _supabaseClient
          .from("deadlines")
          .update(deadlineEntity)
          .select("id");

        id = response.last["id"];

        if(null == id)
          {
            throw FailureToUploadException("Failed to sync deadline on update");
          }
      }
  }

  @override
  Future<void> updateBatch(List<DeadLine> deadlines) async {
      late List<int?> ids;
      late int? id;
      await _isarClient.writeTxn(() async {
        ids = List<int?>.empty(growable: true);
        for(DeadLine d in deadlines)
        {
          d.isSynced = isDevice.Connected.value;
          id = await _isarClient.deadlines.put(d);
          ids.add(id);
        }
      });
      if(ids.any((id) => null == id))
      {
        throw FailureToUpdateException("Failed to update deadlines locally");
      }

      if(isDevice.Connected.value)
      {
        ids.clear();
        List<Map<String, dynamic>> deadlineEntities= deadlines.map((d) => d.toEntity()).toList();
        for(Map<String, dynamic> deadlineEntity in deadlineEntities)
        {
          final List<Map<String, dynamic>> response = await _supabaseClient
              .from("deadlines")
              .update(deadlineEntity)
              .select("id");
          id = response.last["id"];
          ids.add(id);
        }
        if(ids.any((id) => null == id))
        {
          throw FailureToUploadException("Failed to sync deadlines on update");
        }
      }

      }

  @override
  Future<void> retry(List<DeadLine> deadlines) async {
    late List<int?> ids;
    late int? id;

    await _isarClient.writeTxn(() async {
      ids = List<int?>.empty(growable: true);
      for(DeadLine d in deadlines)
      {
        d.isSynced = isDevice.Connected.value;
        id = await _isarClient.deadlines.put(d);
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
      List<Map<String, dynamic>> deadlineEntities= deadlines.map((d) => d.toEntity()).toList();
      for(Map<String, dynamic> deadlineEntity in deadlineEntities)
      {
        final List<Map<String, dynamic>> response = await _supabaseClient
            .from("deadlines")
            .upsert(deadlineEntity)
            .select("id");
        id = response.last["id"];
        ids.add(id);
      }
      if(ids.any((id) => null == id))
      {
        throw FailureToUploadException("Failed to sync deadlines on update");
      }
    }
  }

  @override
  Future<void> delete(DeadLine d) async {
    try
        {
          await _supabaseClient
              .from("deadlines")
              .delete()
              .eq("id", d.id);

          await _isarClient.writeTxn(() async {
            await _isarClient.deadlines.delete(d.id);
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
            .from("deadlines")
            .delete()
            .in_("id", toDeletes);

        await _isarClient.writeTxn(() async {
          // Not sure if I want to store this -> returns a boolean for successful deletion.
          await _isarClient.deadlines.deleteAll(toDeletes);
        });
      }
      catch(error) {
        // I'm also unsure about this Exception.
        throw FailureToDeleteException("Failed to delete deadlines");
      }
    }


    // Get the non-uploaded stuff from Isar.
    List<DeadLine> unsyncedRoutines = await getUnsynced();

    if(unsyncedRoutines.isNotEmpty) {
      List<Map<String, dynamic>> syncEntities = unsyncedRoutines.map((d){d.isSynced = true;return d.toEntity();}).toList();

      final List<Map<String, dynamic>> responses = await _supabaseClient
          .from("deadlines")
          .upsert(syncEntities)
          .select("id");

      List<int?> ids = responses.map((response) => response["id"] as int?).toList();

      if(ids.any((id) => null == id))
      {
        // Any unsynced stuff will just be caught on next sync.
        // This may not need to be a thing to handle.
        throw FailureToUploadException("Failed to Sync deadlines");
      }
    }
    fetchRepo(showLoading: false);
  }
  @override
  Future<void> fetchRepo({bool showLoading = true}) async {
    late List<Map<String, dynamic>> deadlineEntities;

    await Future.delayed(const Duration(seconds: 1)).then((value) async
    {
      if(!isDeviceConnected.value)
      {
        return;
      }
      deadlineEntities = await _supabaseClient
          .from("deadlines")
          .select();

      if(deadlineEntities.isEmpty)
      {
        return;
      }

      List<DeadLine> deadlines = deadlineEntities.map((d) => DeadLine.fromEntity(entity: d)).toList();
      await _isarClient.writeTxn(() async {
        await _isarClient.clear();
        for(DeadLine d in deadlines)
        {
          _isarClient.deadlines.put(d);
        }
      });
    });
  }

  // Custom view position, reorderable list.
  // CHECK THIS and put in proper query logic pls.
  // POSSIBLY PUT A HARD LIMIT?
  @override
  Future<List<DeadLine>> getRepoList({bool showLoading = true}) => _isarClient.deadlines.filter().dueDateGreaterThan(yesterday).findAll();

  @override
  Future<List<DeadLine>> getRepoListBy({bool showLoading = true, Sorter<DeadLine> sorter}) async {
    switch(sorter.sortMethod)
        {
          //TODO: query logic.
      case SortMethod.name:
        if(sorter.descending)
          {
            return _isarClient.deadlines.filter().dueDateGreaterThan(yesterday).findAll();
          }
        else
          {
            return _isarClient.deadlines.filter().dueDateGreaterThan(yesterday).findAll();
          }
      case SortMethod.priority:
        if(sorter.descending)
          {
            return _isarClient.deadlines.filter().dueDateGreaterThan(yesterday).findAll();
          }
        else
          {
            return _isarClient.deadlines.filter().dueDateGreaterThan(yesterday).findAll();
          }
      case SortMethod.dueDate:
        if(sorter.descending)
          {
            return _isarClient.deadlines.filter().dueDateGreaterThan(yesterday).findAll();
          }
        else
          {
            return _isarClient.deadlines.filter().dueDateGreaterThan(yesterday).findAll();
          }
      default:
        return getRepoList(showLoading: false);
    }
  }

  Future<List<int>> getDeleteIds() async => _isarClient.deadlines.filter().toDeleteEqualTo(true).idProperty.findAll();
  Future<List<DeadLine>> getUnsynced() async => _isarClient.deadlines.filter().isSyncedEqualTo(false).findAll();

  DeadLineRepo._internal();

}