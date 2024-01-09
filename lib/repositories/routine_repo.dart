import 'dart:async';

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

class RoutineRepo implements RoutineRepository {
  static final RoutineRepo _instance = RoutineRepo._internal();

  static RoutineRepo get instance => _instance;

  // DB Clients.
  final SupabaseClient _supabaseClient =
      SupabaseService.instance.supabaseClient;
  final Isar _isarClient = IsarService.instance.isarClient;

  @override
  Future<Routine> create(Routine routine) async {
    routine.isSynced = (null != _supabaseClient.auth.currentSession);

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

    if (null != _supabaseClient.auth.currentSession) {
      Map<String, dynamic> routineEntity = routine.toEntity();
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from("routines")
          .insert(routineEntity)
          .select("id");

      id = response.last["id"];

      if (null == id) {
        throw FailureToUploadException("Failed to sync routine on create\n"
            "Routine: ${routine.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }
    return routine;
  }

  @override
  Future<Routine> update(Routine routine) async {
    routine.isSynced = (null != _supabaseClient.auth.currentSession);

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

    if (null != _supabaseClient.auth.currentSession) {
      Map<String, dynamic> routineEntity = routine.toEntity();
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from("routines")
          .upsert(routineEntity)
          .select("id");

      id = response.last["id"] as int?;
      if (null == id) {
        throw FailureToUploadException("Failed to sync routine on update\n"
            "Routine: ${routine.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
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
        routine.isSynced = (null != _supabaseClient.auth.currentSession);
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

    if (null != _supabaseClient.auth.currentSession) {
      ids.clear();
      List<Map<String, dynamic>> routineEntities =
          routines.map((routine) => routine.toEntity()).toList();
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from("routines")
          .upsert(routineEntities)
          .select("id");

      ids = response.map((response) => response["id"] as int?).toList();

      if (ids.any((id) => null == id)) {
        throw FailureToUploadException("Failed to sync routines on update\n"
            "Routines: ${routines.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
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
    if (null != _supabaseClient.auth.currentSession) {
      try {
        await _supabaseClient.from("routines").delete().eq("id", routine.id);
      } catch (error) {
        throw FailureToDeleteException("Failed to delete Routine online\n"
            "Routine: ${routine.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }
    // Delete local
    await _isarClient.writeTxn(() async {
      await _isarClient.routines.delete(routine.id);
    });
  }

  @override
  Future<List<int>> emptyTrash() async {
    if (null != _supabaseClient.auth.currentSession) {
      try {
        await _supabaseClient.from("routines").delete().eq("toDelete", true);
      } catch (error) {
        throw FailureToDeleteException("Failed to empty trash online\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
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
  Future<void> deleteSweep() async {
    List<int> toDeletes = await getDeleteIDs();
    await _isarClient.writeTxn(() async {
      await _isarClient.routines.deleteAll(toDeletes);
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
            .from("routines")
            .delete()
            .inFilter("id", toDeletes);
      } catch (error) {
        throw FailureToDeleteException("Failed to delete routines on sync\n"
            "ids: ${toDeletes.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }

    // Get the non-uploaded stuff from Isar.
    List<Routine> unsyncedRoutines = await getUnsynced();

    if (unsyncedRoutines.isNotEmpty) {
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
        throw FailureToUploadException("Failed to sync routines\n"
            "Routines: ${unsyncedRoutines.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }
    fetchRepo();
  }

  @override
  Future<void> fetchRepo() async {
    late List<Map<String, dynamic>> routineEntities;

    await Future.delayed(const Duration(seconds: 1)).then((value) async {
      if (null == _supabaseClient.auth.currentSession) {
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
        await _isarClient.routines.clear();
        for (Routine routine in routines) {
          await _isarClient.routines.put(routine);
        }
      });
    });
  }

  // TODO: possibly factor the magic number out.
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

  // TODO: Migrate to other repositories
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
