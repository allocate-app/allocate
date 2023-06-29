import 'dart:async';

import 'package:allocate/services/isar_service.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//TODO: Check this and determine how best to handle internet connection.
import '../main.dart';
import '../model/task/routine.dart';
import '../services/supabase_service.dart';
import '../util/exceptions.dart';
import '../util/interfaces/repository.dart';

class RoutineRepository with ChangeNotifier implements Repository<Routine> {

  // DB Clients.
  final SupabaseClient _supabaseClient = SupabaseService.supabaseClient;
  final Isar _isarClient = IsarService.isarClient;

  @override
  Future<void> create(Routine routine) async
  {
    routine.isSynced = isDeviceConnected.value;

    late int? id;
    await _isarClient.writeTxn(() async {
      //This will require to be corrected once db is generated.
      id = await _isarClient.routines.put(routine);
    }
    );

    if(null == id)
    {
      throw FailureToCreateException("Failed to save Routine");
    }

    routine.id = id!;

    if(isDeviceConnected.value)
    {
      Map<String, dynamic> routineEntity = routine.toEntity();
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from("routines")
          .insert(routineEntity)
          .select("id");

      id = response.last["id"];

      if(null == id)
      {
        throw FailureToUploadException("Failed to Sync routine");
      }
    }
  }

  @override
  Future<void> update(Routine routine) async
  {

  }

  @override
  Future<void> delete(Routine r) async {

  }

  // This predicates on having an internet connection.
  @override
  Future<void> syncRepo({bool showLoading = true}) async
  {
    // Get the non-deleted stuff from Isar
    List<int> toDeletes = await getDeleteIds();
    if(toDeletes.isNotEmpty)
      {
       try{
         await _supabaseClient
             .from("routines")
             .delete()
             .in_("id", toDeletes);

         await _isarClient.writeTxn(() async {
           // Not sure if I want to store this -> returns a boolean for successful deletion.
           await _isarClient.routines.deleteAll(toDeletes);
         });
       }
       catch(error) {
         // I'm also unsure about this Exception.
          throw FailureToDeleteException("Failed to Delete Routines");
        }
      }


    // Get the non-uploaded stuff from Isar.
    List<Routine> unsyncedRoutines = await getUnsynced();

    if(unsyncedRoutines.isNotEmpty) {
      List<Map<String, dynamic>> syncEntities = unsyncedRoutines.map((rt){rt.isSynced = true;return rt.toEntity();}).toList();

      final List<Map<String, dynamic>> responses = await _supabaseClient
          .from("routines")
          .upsert(syncEntities)
          .select("id");

      List<int?> ids = responses.map((response) => response["id"] as int?).toList();

      if(ids.any((id) => null == id))
        {
          // Any unsynced stuff will just be caught on next sync.
          throw FailureToUploadException("Failed to Sync Routines");
        }
    }
    // Fetch from supabase.
    fetchRepo(showLoading: false);
  }

  @override
  Future<void> fetchRepo({bool showLoading = true}) async {
    // This needs refactoring to work with a loading widget -> Factor into provider.
    // showLoading ? startLoading() : null;
    late List<Map<String, dynamic>> routineEntities;

    await Future.delayed(const Duration(seconds: 1)).then((value) async
    {
      if(!isDeviceConnected.value)
        {
          return;
        }
      routineEntities = await _supabaseClient
          .from("routines")
          .select();

      if(routineEntities.isEmpty)
        {
          return;
        }

      List<Routine> routines = routineEntities.map((rt) => Routine.fromEntity(entity: rt)).toList();
      await _isarClient.writeTxn(() async {
        await _isarClient.clear();
        for(Routine routine in routines)
        {
          _isarClient.routines.put(routine);
        }
      });
    });
    //stopLoading();
    // This should have a callback that gets the repo list by sort.
  }

  @override
  Future<List<Routine>> getRepoList({bool showLoading = true}) async {
    // TODO: implement getRepoList
    throw UnimplementedError();
  }

  @override
  Future<List<Routine>> getRepoListBy({bool showLoading = true}) async {
    // TODO: implement getRepoListBy
    throw UnimplementedError();
  }

  // This needs to be from local.
  Future<List<int>> getDeleteIds() async => _isarClient.routines.filter().toDeleteEqualTo(true).idProperty.findAll();
  Future<List<Routine>> getUnsynced() async => _isarClient.routines.filter().isSyncedEqualTo(false).findAll();


}
