import 'dart:async';
import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/isar_service.dart';
import '../services/supabase_service.dart';
//TODO: Check this and determine how best to handle internet connection.
import '../main.dart';
import '../model/task/routine.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/interfaces/repository.dart';
import '../util/sorters/routine_sorter.dart';

class RoutineRepository implements Repository<Routine> {
  // DB Clients.
  final SupabaseClient _supabaseClient = SupabaseService.supabaseClient;
  final Isar _isarClient = IsarService.isarClient;

  @override
  Future<void> create(Routine rt) async {
    rt.isSynced = isDeviceConnected.value;

    late int? id;
    await _isarClient.writeTxn(() async {
      //This will require to be corrected once db is generated.
      id = await _isarClient.routines.put(rt);
    });

    if (null == id) {
      throw FailureToCreateException("Failed to create routine locally");
    }

    rt.id = id!;

    if (isDeviceConnected.value) {
      Map<String, dynamic> routineEntity = rt.toEntity();
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
  Future<void> update(Routine rt) async {
    rt.isSynced = isDeviceConnected.value;

    // This is just for error checking.
    late int? id;
    await _isarClient.writeTxn(() async {
      id = await _isarClient.routines.put(rt);
    });

    if (null == id) {
      throw FailureToUpdateException("Failed to update routine locally");
    }

    if (isDeviceConnected.value) {
      Map<String, dynamic> routineEntity = rt.toEntity();
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
        routine.isSynced = isDevice.Connected.value;
        id = await _isarClient.routines.put(routine);
        ids.add(id);
      }
    });
    if (ids.any((id) => null == id)) {
      throw FailureToUpdateException("Failed to update routines locally");
    }

    if (isDevice.Connected.value) {
      ids.clear();
      List<Map<String, dynamic>> routineEntities =
          routines.map((rt) => rt.toEntity()).toList();
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
  Future<void> delete(Routine rt) async {
    //TODO: Finish this implementation.
  }

  @override
  Future<void> retry(List<Routine> routines) async {
    late List<int?> ids;
    late int? id;

    await _isarClient.writeTxn(() async {
      ids = List<int?>.empty(growable: true);
      for (Routine rt in routines) {
        rt.isSynced = isDevice.Connected.value;
        id = await _isarClient.routines.put(rt);
        ids.add(id);
      }
    });
    if (ids.any((id) => null == id)) {
      throw FailureToUpdateException("Failed to update routines locally");
    }

    if (isDevice.Connected.value) {
      ids.clear();
      List<Map<String, dynamic>> routineEntities =
          routines.map((rt) => rt.toEntity()).toList();
      for (Map<String, dynamic> routineEntity in routineEntities) {
        final List<Map<String, dynamic>> response = await _supabaseClient
            .from("routines")
            .upsert(routineEntity)
            .select("id");
        id = response.last["id"] as int?;
        ids.add(id);
      }
      if (ids.any((id) => null == id)) {
        throw FailureToUploadException("Failed to sync routines on update");
      }
    }
  }

  // This predicates on having an internet connection.
  @override
  Future<void> syncRepo({bool showLoading = true}) async {
    // Get the non-deleted stuff from Isar
    List<int> toDeletes = await getDeleteIds();
    if (toDeletes.isEmpty) {
      return fetchRepo(showLoading: false);
    }

    try {
      await _supabaseClient.from("routines").delete().in_("id", toDeletes);

      await _isarClient.writeTxn(() async {
        // Not sure if I want to store this -> returns a boolean for successful deletion.
        await _isarClient.routines.deleteAll(toDeletes);
      });
    } catch (error) {
      // I'm also unsure about this Exception.
      throw FailureToDeleteException("Failed to delete routines");
    }

    // Get the non-uploaded stuff from Isar.
    List<Routine> unsyncedRoutines = await getUnsynced();

    if (unsyncedRoutines.isEmpty) {
      return fetchRepo(showLoading: false);
    }

    List<Map<String, dynamic>> syncEntities = unsyncedRoutines.map((rt) {
      rt.isSynced = true;
      return rt.toEntity();
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
    fetchRepo(showLoading: false);
  }

  @override
  Future<void> fetchRepo({bool showLoading = true}) async {
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

      List<Routine> routines =
          routineEntities.map((rt) => Routine.fromEntity(entity: rt)).toList();
      await _isarClient.writeTxn(() async {
        await _isarClient.clear();
        for (Routine routine in routines) {
          _isarClient.routines.put(routine);
        }
      });
    });
    //stopLoading();
    // This should have a callback that gets the repo list by sort.
  }

  @override
  Future<List<Routine>> getRepoList() async {
    return _isarClient.routines
        .filter()
        .sortByRoutineTime()
        .thenByCustomViewIndex()
        .findAll();
  }

  @override
  Future<List<Routine>> getRepoListBy(
      {required covariant RoutineSortable sorter}) async {
    switch (sorter.sortMethod) {
      case SortMethod.name:
        if (sorter.descending) {
          return _isarClient.routines
              .filter()
              .routineTimeEqualTo(sorter.timeOfDay)
              .sortByNameDesc();
        }
        return _isarClient.routines
            .filter()
            .routineTimeEqualTo(sorter.timeOfDay)
            .sortByName();
      case SortMethod.weight:
        if (sorter.descending) {
          return _isarClient.routines
              .filter()
              .routineTimeEqualTo(sorter.timeOfDay)
              .sortByWeightDesc();
        }
        return _isarClient.routines
            .filter()
            .routineTimeEqualTo(sorter.timeOfDay)
            .sortByWeight();

      case SortMethod.duration:
        if (sorter.descending) {
          return _isarClient.routines
              .filter()
              .routineTimeEqualTo(sorter.timeOfDay)
              .sortByRealDurationDesc();
        }
        return _isarClient.routines
            .filter()
            .routineTimeEqualTo(sorter.timeOfDay)
            .sortByRealDuration();

      default:
        return _isarClient.routines
            .filter()
            .routineTimeEqualTo(sorter.timeOfDay)
            .sortByCustomViewIndex();
    }
  }

  // This needs to be from local.
  Future<List<int>> getDeleteIds() async =>
      _isarClient.routines.filter().toDeleteEqualTo(true).idProperty.findAll();
  Future<List<Routine>> getUnsynced() async =>
      _isarClient.routines.filter().isSyncedEqualTo(false).findAll();
}
