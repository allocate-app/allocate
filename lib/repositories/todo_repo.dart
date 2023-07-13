import 'dart:async';

import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//TODO: Check this and determine how best to handle internet connection.
import '../main.dart';
import '../model/task/todo.dart';
import '../services/isar_service.dart';
import '../services/supabase_service.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/interfaces/repository/todo_repository.dart';
import '../util/interfaces/sorting/sortable.dart';

class ToDoRepo implements ToDoRepository {
  final SupabaseClient _supabaseClient = SupabaseService.supabaseClient;
  final Isar _isarClient = IsarService.isarClient;

  @override
  Future<void> create(ToDo todo) async {
    todo.isSynced = isDeviceConnected.value;

    late int? id;
    await _isarClient.writeTxn(() async {
      //This will require to be corrected once db is generated.
      id = await _isarClient.todos.put(todo);
    });

    if (null == id) {
      throw FailureToCreateException("Failed to create ToDo locally");
    }

    todo.id = id!;

    if (isDeviceConnected.value) {
      Map<String, dynamic> todoEntity = todo.toEntity();
      final List<Map<String, dynamic>> response =
          await _supabaseClient.from("todos").insert(todoEntity).select("id");

      id = response.last["id"];

      if (null == id) {
        throw FailureToUploadException("Failed to sync ToDo on create");
      }
    }
  }

  @override
  Future<void> update(ToDo todo) async {
    todo.isSynced = isDeviceConnected.value;

    // This is just for error checking.
    late int? id;
    await _isarClient.writeTxn(() async {
      id = await _isarClient.todos.put(todo);
    });

    if (null == id) {
      throw FailureToUpdateException("Failed to update todo locally");
    }

    if (isDeviceConnected.value) {
      Map<String, dynamic> todoEntity = todo.toEntity();
      final List<Map<String, dynamic>> response =
          await _supabaseClient.from("todos").update(todoEntity).select("id");

      id = response.last["id"];
      if (null == id) {
        throw FailureToUploadException("Failed to sync todo on update");
      }
    }
  }

  @override
  Future<void> updateBatch(List<ToDo> todos) async {
    late List<int?> ids;
    late int? id;

    await _isarClient.writeTxn(() async {
      ids = List<int?>.empty(growable: true);
      for (ToDo todo in todos) {
        todo.isSynced = isDeviceConnected.value;
        id = await _isarClient.todos.put(todo);
        ids.add(id);
      }
    });
    if (ids.any((id) => null == id)) {
      throw FailureToUpdateException("Failed to update todos locally");
    }

    if (isDeviceConnected.value) {
      ids.clear();
      List<Map<String, dynamic>> todoEntities =
          todos.map((todo) => todo.toEntity()).toList();
      for (Map<String, dynamic> todoEntity in todoEntities) {
        final List<Map<String, dynamic>> response =
            await _supabaseClient.from("todos").update(todoEntity).select("id");
        id = response.last["id"] as int?;
        ids.add(id);
      }
      if (ids.any((id) => null == id)) {
        throw FailureToUploadException("Failed to sync todos on update");
      }
    }
  }

  @override
  Future<void> delete(ToDo todo) async {
    // TODO: NON-ONLINE IMPLEMENTATION, SYNC ISN'T CALLED.
    // if (!user.syncOnline) {
    //   late int? id;
    //   await _isarClient.writeTxn(() async {
    //     id = await _isarClient.todos.delete(todo.id);
    //   });
    //   if (null == id) {
    //     throw FailureToDeleteException("Failed to delete todo locally");
    //   }
    //   return;
    // }
    if (!isDeviceConnected.value) {
      todo.toDelete = true;
      update(todo);
      return;
    }

    try {
      await _supabaseClient.from("todos").delete().eq("id", todo.id);
    } catch (error) {
      throw FailureToDeleteException("Failed to delete todo online");
    }
  }

  @override
  Future<void> retry(List<ToDo> todos) async {
    late List<int?> ids;
    late int? id;

    await _isarClient.writeTxn(() async {
      ids = List<int?>.empty(growable: true);
      for (ToDo todo in todos) {
        todo.isSynced = isDeviceConnected.value;
        id = await _isarClient.todos.put(todo);
        ids.add(id);
      }
    });
    if (ids.any((id) => null == id)) {
      throw FailureToUpdateException("Failed to update todos locally");
    }

    if (isDeviceConnected.value) {
      ids.clear();
      List<Map<String, dynamic>> todoEntities =
          todos.map((todo) => todo.toEntity()).toList();
      final List<Map<String, dynamic>> responses =
          await _supabaseClient.from("todos").upsert(todoEntities).select("id");

      ids = responses.map((response) => response["id"] as int?).toList();

      if (ids.any((id) => null == id)) {
        throw FailureToUploadException("Failed to sync todos on update");
      }
    }
  }

  @override
  Future<void> syncRepo({bool showLoading = true}) async {
    List<int> toDeletes = await getDeleteIds();
    if (toDeletes.isEmpty) {
      return fetchRepo();
    }

    try {
      await _supabaseClient.from("todos").delete().in_("id", toDeletes);
    } catch (error) {
      // I'm also unsure about this Exception.
      throw FailureToDeleteException("Failed to delete todos on sync");
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
        await _supabaseClient.from("todos").upsert(syncEntities).select("id");

    List<int?> ids =
        responses.map((response) => response["id"] as int?).toList();

    if (ids.any((id) => null == id)) {
      // Any unsynced stuff will just be caught on next sync.
      // This may not need to be a thing to handle.
      throw FailureToUploadException("Failed to sync todos");
    }

    // Fetch from supabase.
    fetchRepo();
  }

  @override
  Future<void> fetchRepo({bool showLoading = true}) async {
    late List<Map<String, dynamic>> todoEntities;

    await Future.delayed(const Duration(seconds: 1)).then((value) async {
      if (!isDeviceConnected.value) {
        return;
      }
      todoEntities = await _supabaseClient.from("todos").select();

      if (todoEntities.isEmpty) {
        return;
      }

      List<ToDo> todos = todoEntities
          .map((routine) => ToDo.fromEntity(entity: routine))
          .toList();
      await _isarClient.writeTxn(() async {
        await _isarClient.clear();
        for (ToDo todo in todos) {
          _isarClient.todos.put(todo);
        }
      });
    });
  }

  @override
  Future<ToDo> getById({required int id}) async =>
      _isarClient.todos.where().idEquals(id).findAll();

  /// These all require to be "completed = false."

  @override
  Future<List<ToDo>> getRepoList() async => _isarClient.todos
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
          return _isarClient.todos
              .where()
              .completedEqualTo(false)
              .filter()
              .toDeleteEqualTo(false)
              .sortByNameDesc()
              .findAll();
        }
        return _isarClient.todos
            .where()
            .completedEqualTo(false)
            .filter()
            .toDeleteEqualTo(false)
            .sortByName()
            .findAll();
      case SortMethod.dueDate:
        if (sorter.descending) {
          return _isarClient.todos
              .where()
              .completedEqualTo(false)
              .filter()
              .toDeleteEqualTo(false)
              .sortByDueDateDesc()
              .findAll();
        }
        return _isarClient.todos
            .where()
            .completedEqualTo(false)
            .filter()
            .toDeleteEqualTo(false)
            .sortByDueDate()
            .findAll();
      case SortMethod.weight:
        if (sorter.descending) {
          return _isarClient.todos
              .where()
              .completedEqualTo(false)
              .filter()
              .toDeleteEqualTo(false)
              .sortByWeightDesc()
              .findAll();
        }
        return _isarClient.todos
            .where()
            .completedEqualTo(false)
            .filter()
            .toDeleteEqualTo(false)
            .sortByWeightDesc()
            .findAll();
      case SortMethod.priority:
        if (sorter.descending) {
          return _isarClient.todos
              .where()
              .completedEqualTo(false)
              .filter()
              .toDeleteEqualTo(false)
              .sortByPriorityDesc()
              .findAll();
        }
        return _isarClient.todos
            .where()
            .completedEqualTo(false)
            .filter()
            .toDeleteEqualTo(false)
            .sortByPriority()
            .findAll();
      case SortMethod.duration:
        if (sorter.descending) {
          return _isarClient.todos
              .where()
              .completedEqualTo(false)
              .filter()
              .toDeleteEqualTo(false)
              .sortByRealDurationDesc()
              .findAll();
        }
        return _isarClient.todos
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
  Future<List<ToDo>> getCompleted() async => _isarClient.todos
      .where()
      .completedEqualTo(true)
      .filter()
      .toDeleteEqualTo(false)
      .findAll();

  @override
  Future<List<ToDo>> getMyDay() async => _isarClient.todos
      .where()
      .myDayEqualTo(true)
      .filter()
      .toDeleteEqualTo(false)
      .completedEqualTo(false)
      .sortByCustomViewIndex()
      .findAll();

  @override
  Future<List<ToDo>> getRepoByGroupID({required int groupID}) async =>
      _isarClient.todos
          .where()
          .groupIDEqualTo(groupID)
          .filter()
          .toDeleteEqualTo(false)
          .completedEqualTo(false)
          .sortByGroupIndex()
          .findAll();

  Future<List<int>> getDeleteIds() async =>
      _isarClient.todos.where().toDeleteEqualTo(true).idProperty.findAll();
  Future<List<ToDo>> getUnsynced() async =>
      _isarClient.todos.where().isSyncedEqualTo(false).findAll();
}
