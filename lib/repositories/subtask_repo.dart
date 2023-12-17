import 'package:allocate/model/task/subtask.dart';
import 'package:allocate/util/interfaces/sortable.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/isar_service.dart';
import '../services/supabase_service.dart';
import '../util/constants.dart';
import '../util/exceptions.dart';
import '../util/interfaces/repository/model/subtask_repository.dart';

class SubtaskRepo implements SubtaskRepository {
  final SupabaseClient _supabaseClient =
      SupabaseService.instance.supabaseClient;
  final Isar _isarClient = IsarService.instance.isarClient;

  @override
  Future<Subtask> create(Subtask subTask) async {
    subTask.isSynced = (null != _supabaseClient.auth.currentSession);
    late int? id;
    await _isarClient.writeTxn(() async {
      id = await _isarClient.subtasks.put(subTask);
    });

    if (null == id) {
      throw FailureToCreateException("Failed to create Subtask locally \n"
          "Subtask: ${subTask.toString()}\n"
          "Time: ${DateTime.now()}\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (null != _supabaseClient.auth.currentSession) {
      Map<String, dynamic> subtaskEntity = subTask.toEntity();
      final List<Map<String, dynamic>> response =
          await _supabaseClient.from("ts").insert(subtaskEntity).select("id");

      id = response.last["id"];

      if (null == id) {
        throw FailureToUploadException("Failed to sync Subtask on create\n"
            "Subtask: ${subTask.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }

    return subTask;
  }

  @override
  Future<void> delete(Subtask subTask) async {
    if (null == _supabaseClient.auth.currentSession) {
      subTask.toDelete = true;
      await update(subTask);
      return;
    }

    try {
      await _supabaseClient.from("subtasks").delete().eq("id", subTask.id);
      await _isarClient.writeTxn(() async {
        await _isarClient.subtasks.delete(subTask.id);
      });
    } catch (error) {
      throw FailureToDeleteException("Failed to delete Subtask online\n"
          "Subtask: ${subTask.toString()}\n"
          "Time: ${DateTime.now()}\n"
          "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
    }
  }

  @override
  Future<void> deleteLocal() async {
    List<int> toDeletes = await getDeleteIds();
    await _isarClient.writeTxn(() async {
      await _isarClient.subtasks.deleteAll(toDeletes);
    });
  }

  @override
  Future<void> fetchRepo() async {
    late List<Map<String, dynamic>> subTaskEntities;

    await Future.delayed(const Duration(seconds: 1)).then((value) async {
      if (null == _supabaseClient.auth.currentSession) {
        return;
      }
      subTaskEntities = await _supabaseClient.from("subtasks").select();

      if (subTaskEntities.isEmpty) {
        return;
      }

      List<Subtask> subtasks = subTaskEntities
          .map((subTask) => Subtask.fromEntity(entity: subTask))
          .toList();
      await _isarClient.writeTxn(() async {
        await _isarClient.subtasks.clear();
        for (Subtask subTask in subtasks) {
          await _isarClient.subtasks.put(subTask);
        }
      });
    });
  }

  @override
  Future<Subtask?> getByID({required int id}) async =>
      await _isarClient.subtasks.where().idEqualTo(id).findFirst();

  @override
  Future<List<Subtask>> getRepoList({int limit = 50, int offset = 0}) async =>
      await _isarClient.subtasks.where().offset(offset).limit(limit).findAll();

  // No subtask sorting atm.
  @override
  Future<List<Subtask>> getRepoListBy(
          {int limit = Constants.maxNumTasks,
          int offset = 0,
          required SortableView<Subtask> sorter}) async =>
      await getRepoList(limit: limit, offset: offset);

  @override
  Future<int> getTaskSubtasksCount(
          {required int taskID, int limit = Constants.maxNumTasks}) async =>
      await _isarClient.subtasks
          .where()
          .taskIDEqualTo(taskID)
          .sortByCustomViewIndex()
          .thenByLastUpdated()
          .limit(limit)
          .count();

  @override
  Future<int> getTotalSubtaskWeight(
          {required int taskID, int limit = Constants.maxNumTasks}) async =>
      await _isarClient.subtasks
          .where()
          .taskIDEqualTo(taskID)
          .filter()
          .toDeleteEqualTo(false)
          .completedEqualTo(false)
          .sortByCustomViewIndex()
          .thenByLastUpdated()
          .limit(limit)
          .weightProperty()
          .sum();

  @override
  Future<List<Subtask>> getRepoByTaskID(
          {required int id, int limit = 50, int offset = 0}) async =>
      await _isarClient.subtasks
          .where()
          .taskIDEqualTo(id)
          .filter()
          .toDeleteEqualTo(false)
          .sortByCustomViewIndex()
          .thenByLastUpdated()
          .offset(offset)
          .limit(limit)
          .findAll();

  @override
  Future<void> syncRepo() async {
    if (null == _supabaseClient.auth.currentSession) {
      return fetchRepo();
    }
    List<int> toDeletes = await getDeleteIds();
    if (toDeletes.isNotEmpty) {
      try {
        await _supabaseClient.from("subtasks").delete().in_("id", toDeletes);
      } catch (error) {
        throw FailureToDeleteException("Failed to delete subtasks on sync.\n"
            "ids: ${toDeletes.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }

    // Get the non-uploaded stuff from Isar.
    List<Subtask> unsyncedSubtasks = await getUnsynced();

    if (unsyncedSubtasks.isNotEmpty) {
      List<Map<String, dynamic>> syncEntities = unsyncedSubtasks.map((subTask) {
        subTask.isSynced = true;
        return subTask.toEntity();
      }).toList();

      final List<Map<String, dynamic>> responses = await _supabaseClient
          .from("subtasks")
          .upsert(syncEntities)
          .select("id");

      List<int?> ids =
          responses.map((response) => response["id"] as int?).toList();

      if (ids.any((id) => null == id)) {
        unsyncedSubtasks.map((subTask) => subTask.isSynced = false);
        throw FailureToUploadException("Failed to sync subtasks\n"
            "Subtasks: ${unsyncedSubtasks.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }
    fetchRepo();
  }

  @override
  Future<Subtask> update(Subtask subTask) async {
    subTask.isSynced = (null != _supabaseClient.auth.currentSession);

    // This is just for error checking.
    late int? id;
    await _isarClient.writeTxn(() async {
      id = await _isarClient.subtasks.put(subTask);
    });

    if (null == id) {
      throw FailureToUpdateException("Failed to update Subtask locally\n"
          "Subtask: ${subTask.toString()}\n"
          "Time: ${DateTime.now()}\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (null != _supabaseClient.auth.currentSession) {
      Map<String, dynamic> subtaskEntity = subTask.toEntity();
      final List<Map<String, dynamic>> response =
          await _supabaseClient.from("ts").upsert(subtaskEntity).select("id");

      id = response.last["id"];
      if (null == id) {
        throw FailureToUploadException("Failed to sync Subtask on update\n"
            "Subtask: ${subTask.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }
    return subTask;
  }

  @override
  Future<void> updateBatch(List<Subtask> subtasks) async {
    late List<int?> ids;
    late int? id;

    await _isarClient.writeTxn(() async {
      ids = List<int?>.empty(growable: true);
      for (Subtask subTask in subtasks) {
        subTask.isSynced = (null != _supabaseClient.auth.currentSession);
        id = await _isarClient.subtasks.put(subTask);
        ids.add(id);
      }
    });
    if (ids.any((id) => null == id)) {
      throw FailureToUpdateException("Failed to update subtasks locally \n"
          "Subtask: ${subtasks.toString()}\n"
          "Time: ${DateTime.now()}\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (null != _supabaseClient.auth.currentSession) {
      ids.clear();
      List<Map<String, dynamic>> subTaskEntities =
          subtasks.map((subTask) => subTask.toEntity()).toList();
      final List<Map<String, dynamic>> responses = await _supabaseClient
          .from("subtasks")
          .upsert(subTaskEntities)
          .select("id");

      ids = responses.map((response) => response["id"] as int?).toList();

      if (ids.any((id) => null == id)) {
        throw FailureToUploadException("Failed to sync subtasks on update \n"
            "Subtask: ${subtasks.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }
  }

  Future<List<int>> getDeleteIds() async => await _isarClient.subtasks
      .where()
      .toDeleteEqualTo(true)
      .idProperty()
      .findAll();

  Future<List<Subtask>> getUnsynced() async =>
      await _isarClient.subtasks.where().isSyncedEqualTo(false).findAll();
}
