import 'dart:async';

import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//TODO: Check this and determine how best to handle internet connection.
import '../main.dart';
import '../model/task/routine.dart';
import '../services/isar_service.dart';
import '../services/supabase_service.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/interfaces/repository/routine_repository.dart';
import '../util/interfaces/sorting/sortable.dart';

class RoutineRepo implements RoutineRepository {
  // DB Clients.
  final SupabaseClient _supabaseClient = SupabaseService.supabaseClient;
  final Isar _isarClient = IsarService.isarClient;

  RoutineRepo();

  @override
  Future<void> create(Routine routine) async {
    routine.isSynced = isDeviceConnected.value;

    late int? id;
    await _isarClient.writeTxn(() async {
      //This will require to be corrected once db is generated.
      id = await _isarClient.routines.put(routine);
    });

    if (null == id) {
      throw FailureToCreateException("Failed to create routine locally");
    }

    routine.id = id!;

    if (isDeviceConnected.value) {
      Map<String, dynamic> routineEntity = routine.toEntity();
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from("routines")
          .insert(routineEntity)
          .select("id");

      id = response.last["id"];

      if (null == id) {
        throw FailureToUploadException("Failed to sync routine on create");
      }
    }
  }

  @override
  Future<void> update(Routine routine) async {
    routine.isSynced = isDeviceConnected.value;

    // This is just for error checking.
    late int? id;
    await _isarClient.writeTxn(() async {
      id = await _isarClient.routines.put(routine);
    });

    if (null == id) {
      throw FailureToUpdateException("Failed to update routine locally");
    }

    if (isDeviceConnected.value) {
      Map<String, dynamic> routineEntity = routine.toEntity();
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from("routines")
          .update(routineEntity)
          .select("id");

      id = response.last["id"] as int?;
      if (null == id) {
        throw FailureToUploadException("Failed to sync routine on update");
      }
    }
  }

  @override
  Future<void> updateBatch(List<Routine> routines) async {
    late List<int?> ids;
    late int? id;

    await _isarClient.writeTxn(() async {
      ids = List<int?>.empty(growable: true);
      for (Routine routine in routines) {
        routine.isSynced = isDeviceConnected.value;
        id = await _isarClient.routines.put(routine);
        ids.add(id);
      }
    });
    if (ids.any((id) => null == id)) {
      throw FailureToUpdateException("Failed to update routines locally");
    }

    if (isDeviceConnected.value) {
      ids.clear();
      List<Map<String, dynamic>> routineEntities =
          routines.map((routine) => routine.toEntity()).toList();
      for (Map<String, dynamic> routineEntity in routineEntities) {
        final List<Map<String, dynamic>> response = await _supabaseClient
            .from("routines")
            .update(routineEntity)
            .select("id");
        id = response.last["id"] as int?;
        ids.add(id);
      }
      if (ids.any((id) => null == id)) {
        throw FailureToUploadException("Failed to sync routines on update");
      }
    }
  }

  @override
  Future<void> delete(Routine routine) async {
    // TODO: NON-ONLINE IMPLEMENTATION, SYNC ISN'T CALLED.
    // if (!user.syncOnline) {
    //   late int? id;
    //   await _isarClient.writeTxn(() async {
    //     id = await _isarClient.routines.delete(routine.id);
    //   });
    //   if (null == id) {
    //     throw FailureToDeleteException("Failed to delete routine locally");
    //   }
    //   return;
    // }
    if (!isDeviceConnected.value) {
      routine.toDelete = true;
      update(routine);
      return;
    }

    try {
      await _supabaseClient.from("routines").delete().eq("id", routine.id);
    } catch (error) {
      throw FailureToDeleteException("Failed to delete routine online");
    }
  }

  @override
  Future<void> retry(List<Routine> routines) async {
    late List<int?> ids;
    late int? id;

    await _isarClient.writeTxn(() async {
      ids = List<int?>.empty(growable: true);
      for (Routine routine in routines) {
        routine.isSynced = isDeviceConnected.value;
        id = await _isarClient.routines.put(routine);
        ids.add(id);
      }
    });
    if (ids.any((id) => null == id)) {
      throw FailureToUpdateException("Failed to update routines locally");
    }

    if (isDeviceConnected.value) {
      ids.clear();
      List<Map<String, dynamic>> routineEntities =
          routines.map((routine) => routine.toEntity()).toList();
      final List<Map<String, dynamic>> responses = await _supabaseClient
          .from("routines")
          .upsert(routineEntities)
          .select("id");

      ids = responses.map((response) => response["id"] as int?).toList();

      if (ids.any((id) => null == id)) {
        throw FailureToUploadException("Failed to sync routines on update");
      }
    }
  }

  // This predicates on having an internet connection.
  @override
  Future<void> syncRepo() async {
    // Get the non-deleted stuff from Isar
    List<int> toDeletes = await getDeleteIds();
    if (toDeletes.isEmpty) {
      return fetchRepo();
    }

    try {
      await _supabaseClient.from("routines").delete().in_("id", toDeletes);
    } catch (error) {
      // I'm also unsure about this Exception.
      throw FailureToDeleteException("Failed to delete routines on sync");
    }

    // Get the non-uploaded stuff from Isar.
    List<Routine> unsyncedRoutines = await getUnsynced();

    if (unsyncedRoutines.isEmpty) {
      return fetchRepo();
    }

    List<Map<String, dynamic>> syncEntities = unsyncedRoutines.map((routine) {
      routine.isSynced = true;
      return routine.toEntity();
    }).toList();

    final List<Map<String, dynamic>> responses = await _supabaseClient
        .from("routines")
        .upsert(syncEntities)
        .select("id");

    List<int?> ids =
        responses.map((response) => response["id"] as int?).toList();

    if (ids.any((id) => null == id)) {
      // Any unsynced stuff will just be caught on next sync.
      // This may not need to be a thing to handle.
      throw FailureToUploadException("Failed to sync routines");
    }

    // Fetch from supabase.
    fetchRepo();
  }

  @override
  Future<void> fetchRepo() async {
    // This needs refactoring to work with a loading widget -> Factor into provider.
    // showLoading ? startLoading() : null;
    late List<Map<String, dynamic>> routineEntities;

    await Future.delayed(const Duration(seconds: 1)).then((value) async {
      if (!isDeviceConnected.value) {
        return;
      }
      routineEntities = await _supabaseClient.from("routines").select();

      if (routineEntities.isEmpty) {
        return;
      }

      List<Routine> routines = routineEntities
          .map((routine) => Routine.fromEntity(entity: routine))
          .toList();
      await _isarClient.writeTxn(() async {
        await _isarClient.clear();
        for (Routine routine in routines) {
          _isarClient.routines.put(routine);
        }
      });
    });
    // This should have a callback that gets the repo list by sort.
  }

  @override
  Future<List<Routine>> getRepoList(
      {RoutineTime timeOfDay = RoutineTime.morning}) async {
    return _isarClient.routines
        .filter()
        .toDeleteEqualTo(false)
        .routineTimeEqualTo(timeOfDay)
        .sortByCustomViewIndex()
        .findAll();
  }

  @override
  Future<List<Routine>> getRepoListBy(
      {RoutineTime timeOfDay = RoutineTime.morning,
      required SortableView<Routine> sorter}) async {
    switch (sorter.sortMethod) {
      case SortMethod.name:
        if (sorter.descending) {
          return _isarClient.routines
              .filter()
              .toDeleteEqualTo(false)
              .routineTimeEqualTo(timeOfDay)
              .sortByNameDesc()
              .findAll();
        }
        return _isarClient.routines
            .filter()
            .toDeleteEqualTo(false)
            .routineTimeEqualTo(timeOfDay)
            .sortByName()
            .findAll();

      case SortMethod.weight:
        if (sorter.descending) {
          return _isarClient.routines
              .filter()
              .toDeleteEqualTo(false)
              .routineTimeEqualTo(timeOfDay)
              .sortByWeightDesc()
              .findAll();
        }
        return _isarClient.routines
            .filter()
            .toDeleteEqualTo(false)
            .routineTimeEqualTo(timeOfDay)
            .sortByWeight()
            .findAll();

      case SortMethod.duration:
        if (sorter.descending) {
          return _isarClient.routines
              .filter()
              .toDeleteEqualTo(false)
              .routineTimeEqualTo(timeOfDay)
              .sortByRealDurationDesc()
              .findAll();
        }
        return _isarClient.routines
            .filter()
            .toDeleteEqualTo(false)
            .routineTimeEqualTo(timeOfDay)
            .sortByRealDuration()
            .findAll();

      default:
        return getRepoList(timeOfDay: timeOfDay);
    }
  }

  // This needs to be from local.
  Future<List<int>> getDeleteIds() async =>
      _isarClient.routines.filter().toDeleteEqualTo(true).idProperty.findAll();
  Future<List<Routine>> getUnsynced() async =>
      _isarClient.routines.filter().isSyncedEqualTo(false).findAll();
}
