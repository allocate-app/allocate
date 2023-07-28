import 'dart:async';

import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//TODO: Check this and determine how best to handle internet connection.
import '../model/task/todo.dart';
import '../services/isar_service.dart';
import '../services/supabase_service.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/interfaces/repository/todo_repository.dart';
import '../util/interfaces/sortable.dart';

class ToDoRepo implements ToDoRepository {
  final SupabaseClient _supabaseClient = SupabaseService.instance.supabaseClient;
  final Isar _isarClient = IsarService.instance.isarClient;

  @override
  Future<void> create(ToDo todo) async {
    todo.isSynced = (null != _supabaseClient.auth.currentSession);

    late int? id;
    await _isarClient.writeTxn(() async {
      //This will require to be corrected once db is generated.
      id = await _isarClient.toDos.put(todo);
    });

    if (null == id) {
      throw FailureToCreateException("Failed to create ToDo locally");
    }

    todo.id = id!;

    if (null != _supabaseClient.auth.currentSession) {
      Map<String, dynamic> todoEntity = todo.toEntity();
      final List<Map<String, dynamic>> response =
          await _supabaseClient.from("toDos").insert(todoEntity).select("id");

      id = response.last["id"];

      if (null == id) {
        throw FailureToUploadException("Failed to sync ToDo on create");
      }
    }
  }

  @override
  Future<void> update(ToDo todo) async {
    todo.isSynced = (null != _supabaseClient.auth.currentSession);

    // This is just for error checking.
    late int? id;
    await _isarClient.writeTxn(() async {
      id = await _isarClient.toDos.put(todo);
    });

    if (null == id) {
      throw FailureToUpdateException("Failed to update todo locally");
    }

    if (null != _supabaseClient.auth.currentSession) {
      Map<String, dynamic> todoEntity = todo.toEntity();
      final List<Map<String, dynamic>> response =
          await _supabaseClient.from("toDos").upsert(todoEntity).select("id");

      id = response.last["id"];
      if (null == id) {
        throw FailureToUploadException("Failed to sync todo on update");
      }
    }
  }

  @override
  Future<void> updateBatch(List<ToDo> toDos) async {
    late List<int?> ids;
    late int? id;

    await _isarClient.writeTxn(() async {
      ids = List<int?>.empty(growable: true);
      for (ToDo todo in toDos) {
        todo.isSynced = (null != _supabaseClient.auth.currentSession);
        id = await _isarClient.toDos.put(todo);
        ids.add(id);
      }
    });
    if (ids.any((id) => null == id)) {
      throw FailureToUpdateException("Failed to update toDos locally");
    }

    if (null != _supabaseClient.auth.currentSession) {
      ids.clear();
      List<Map<String, dynamic>> todoEntities =
          toDos.map((todo) => todo.toEntity()).toList();
      final List<Map<String, dynamic>> responses =
          await _supabaseClient.from("toDos").upsert(todoEntities).select("id");

      ids = responses.map((response) => response["id"] as int?).toList();

      if (ids.any((id) => null == id)) {
        throw FailureToUploadException("Failed to sync toDos on update");
      }
    }
  }

  @override
  Future<void> delete(ToDo todo) async {
    if (null != _supabaseClient.auth.currentSession) {
      todo.toDelete = true;
      update(todo);
      return;
    }

    try {
      await _supabaseClient.from("toDos").delete().eq("id", todo.id);
      await _isarClient.writeTxn(() async {
        await _isarClient.toDos.delete(todo.id);
      });
    } catch (error) {
      throw FailureToDeleteException("Failed to delete todo online");
    }
  }

  // This is a "Set stuff up for the next delete on sync" kind of delete.
  // They will be hidden from the view, and removed in the background.
  @override
  Future<void> deleteFutures({required ToDo toDo}) async {
    List<ToDo> toDelete = await _isarClient.toDos
        .where()
        .repeatIDEqualTo(toDo.repeatID)
        .filter()
        .repeatableEqualTo(true)
        .findAll();

    toDelete.map((ToDo t) => t.toDelete = true);
    updateBatch(toDelete);
  }

  @override
  // Call this on a timer if/when user is not syncing data.
  Future<void> deleteLocal() async {
    List<int> toDeletes = await getDeleteIds();
    await _isarClient.writeTxn(() async {
      await _isarClient.toDos.deleteAll(toDeletes);
    });
  }

  @override
  Future<void> syncRepo() async {
    List<int> toDeletes = await getDeleteIds();
    if (toDeletes.isEmpty) {
      return fetchRepo();
    }

    try {
      await _supabaseClient.from("toDos").delete().in_("id", toDeletes);
    } catch (error) {
      // I'm also unsure about this Exception.
      throw FailureToDeleteException("Failed to delete toDos on sync");
    }

    // Get the non-uploaded stuff from Isar.
    List<ToDo> unsyncedTodos = await getUnsynced();

    if (unsyncedTodos.isEmpty) {
      return fetchRepo();
    }

    List<Map<String, dynamic>> syncEntities = unsyncedTodos.map((todo) {
      todo.isSynced = true;
      return todo.toEntity();
    }).toList();

    final List<Map<String, dynamic>> responses =
        await _supabaseClient.from("toDos").upsert(syncEntities).select("id");

    List<int?> ids =
        responses.map((response) => response["id"] as int?).toList();

    if (ids.any((id) => null == id)) {
      // Any unsynced stuff will just be caught on next sync.
      // This may not need to be a thing to handle.
      throw FailureToUploadException("Failed to sync toDos");
    }

    // Fetch from supabase.
    fetchRepo();
  }

  @override
  Future<void> fetchRepo() async {
    late List<Map<String, dynamic>> todoEntities;

    await Future.delayed(const Duration(seconds: 1)).then((value) async {
      if (null == _supabaseClient.auth.currentSession) {
        return;
      }
      todoEntities = await _supabaseClient.from("toDos").select();

      if (todoEntities.isEmpty) {
        return;
      }

      List<ToDo> toDos = todoEntities
          .map((routine) => ToDo.fromEntity(entity: routine))
          .toList();
      await _isarClient.writeTxn(() async {
        await _isarClient.toDos.clear();
        for (ToDo todo in toDos) {
          await _isarClient.toDos.put(todo);
        }
      });
    });
  }

  @override
  Future<ToDo?> getByID({required int id}) async =>
      await _isarClient.toDos.where().idEqualTo(id).findFirst();

  /// These all require to be "completed = false."

  @override
  Future<List<ToDo>> getRepoList() async => _isarClient.toDos
      .where()
      .completedEqualTo(false)
      .filter()
      .toDeleteEqualTo(false)
      .sortByCustomViewIndex()
      .findAll();

  @override
  Future<List<ToDo>> getRepoListBy({required SortableView<ToDo> sorter}) async {
    switch (sorter.sortMethod) {
      case SortMethod.name:
        if (sorter.descending) {
          return _isarClient.toDos
              .where()
              .completedEqualTo(false)
              .filter()
              .toDeleteEqualTo(false)
              .sortByNameDesc()
              .findAll();
        }
        return _isarClient.toDos
            .where()
            .completedEqualTo(false)
            .filter()
            .toDeleteEqualTo(false)
            .sortByName()
            .findAll();
      case SortMethod.dueDate:
        if (sorter.descending) {
          return _isarClient.toDos
              .where()
              .completedEqualTo(false)
              .filter()
              .toDeleteEqualTo(false)
              .sortByDueDateDesc()
              .findAll();
        }
        return _isarClient.toDos
            .where()
            .completedEqualTo(false)
            .filter()
            .toDeleteEqualTo(false)
            .sortByDueDate()
            .findAll();
      case SortMethod.weight:
        if (sorter.descending) {
          return _isarClient.toDos
              .where()
              .completedEqualTo(false)
              .filter()
              .toDeleteEqualTo(false)
              .sortByWeightDesc()
              .findAll();
        }
        return _isarClient.toDos
            .where()
            .completedEqualTo(false)
            .filter()
            .toDeleteEqualTo(false)
            .sortByWeightDesc()
            .findAll();
      case SortMethod.priority:
        if (sorter.descending) {
          return _isarClient.toDos
              .where()
              .completedEqualTo(false)
              .filter()
              .toDeleteEqualTo(false)
              .sortByPriorityDesc()
              .findAll();
        }
        return _isarClient.toDos
            .where()
            .completedEqualTo(false)
            .filter()
            .toDeleteEqualTo(false)
            .sortByPriority()
            .findAll();
      case SortMethod.duration:
        if (sorter.descending) {
          return _isarClient.toDos
              .where()
              .completedEqualTo(false)
              .filter()
              .toDeleteEqualTo(false)
              .sortByRealDurationDesc()
              .findAll();
        }
        return _isarClient.toDos
            .where()
            .completedEqualTo(false)
            .filter()
            .toDeleteEqualTo(false)
            .sortByRealDuration()
            .findAll();
      default:
        return getRepoList();
    }
  }

  @override
  Future<List<ToDo>> getCompleted() async => _isarClient.toDos
      .where()
      .completedEqualTo(true)
      .filter()
      .toDeleteEqualTo(false)
      .findAll();

  @override
  Future<List<ToDo>> getMyDay() async => _isarClient.toDos
      .where()
      .myDayEqualTo(true)
      .filter()
      .toDeleteEqualTo(false)
      .completedEqualTo(false)
      .sortByCustomViewIndex()
      .findAll();

  @override
  Future<List<ToDo>> getRepoByGroupID({required int groupID}) async =>
      _isarClient.toDos
          .where()
          .groupIDEqualTo(groupID)
          .filter()
          .toDeleteEqualTo(false)
          .completedEqualTo(false)
          .sortByGroupIndex()
          .findAll();

  @override
  Future<List<ToDo>> getRepeatables({DateTime? now}) async => _isarClient.toDos
      .where()
      .repeatableEqualTo(true)
      .filter()
      .dueDateLessThan(now ?? DateTime.now())
      .findAll();

  Future<List<int>> getDeleteIds() async =>
      _isarClient.toDos.where().toDeleteEqualTo(true).idProperty().findAll();
  Future<List<ToDo>> getUnsynced() async =>
      _isarClient.toDos.where().isSyncedEqualTo(false).findAll();
}
