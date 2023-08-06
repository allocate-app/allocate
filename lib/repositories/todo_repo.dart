import 'dart:async';

import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/task/todo.dart';
import '../services/isar_service.dart';
import '../services/supabase_service.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/interfaces/repository/todo_repository.dart';
import '../util/interfaces/sortable.dart';

class ToDoRepo implements ToDoRepository {
  final SupabaseClient _supabaseClient =
      SupabaseService.instance.supabaseClient;
  final Isar _isarClient = IsarService.instance.isarClient;

  @override
  Future<void> create(ToDo toDo) async {
    toDo.isSynced = (null != _supabaseClient.auth.currentSession);

    late int? id;
    await _isarClient.writeTxn(() async {
      //This will require to be corrected once db is generated.
      id = await _isarClient.toDos.put(toDo);
    });

    if (null == id) {
      throw FailureToCreateException("Failed to create ToDo locally \n"
          "ToDo: ${toDo.toString()}\n"
          "Time: ${DateTime.now()}\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (null != _supabaseClient.auth.currentSession) {
      Map<String, dynamic> toDoEntity = toDo.toEntity();
      final List<Map<String, dynamic>> response =
          await _supabaseClient.from("toDos").insert(toDoEntity).select("id");

      id = response.last["id"];

      if (null == id) {
        throw FailureToUploadException("Failed to sync ToDo on create\n"
            "ToDo: ${toDo.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }
  }

  @override
  Future<void> update(ToDo toDo) async {
    toDo.isSynced = (null != _supabaseClient.auth.currentSession);

    // This is just for error checking.
    late int? id;
    await _isarClient.writeTxn(() async {
      id = await _isarClient.toDos.put(toDo);
    });

    if (null == id) {
      throw FailureToUpdateException("Failed to update ToDo locally\n"
          "ToDo: ${toDo.toString()}\n"
          "Time: ${DateTime.now()}\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (null != _supabaseClient.auth.currentSession) {
      Map<String, dynamic> toDoEntity = toDo.toEntity();
      final List<Map<String, dynamic>> response =
          await _supabaseClient.from("toDos").upsert(toDoEntity).select("id");

      id = response.last["id"];
      if (null == id) {
        throw FailureToUploadException("Failed to sync ToDo on update\n"
            "ToDo: ${toDo.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }
  }

  @override
  Future<void> updateBatch(List<ToDo> toDos) async {
    late List<int?> ids;
    late int? id;

    await _isarClient.writeTxn(() async {
      ids = List<int?>.empty(growable: true);
      for (ToDo toDo in toDos) {
        toDo.isSynced = (null != _supabaseClient.auth.currentSession);
        id = await _isarClient.toDos.put(toDo);
        ids.add(id);
      }
    });
    if (ids.any((id) => null == id)) {
      throw FailureToUpdateException("Failed to update toDos locally \n"
          "ToDo: ${toDos.toString()}\n"
          "Time: ${DateTime.now()}\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (null != _supabaseClient.auth.currentSession) {
      ids.clear();
      List<Map<String, dynamic>> toDoEntities =
          toDos.map((toDo) => toDo.toEntity()).toList();
      final List<Map<String, dynamic>> responses =
          await _supabaseClient.from("toDos").upsert(toDoEntities).select("id");

      ids = responses.map((response) => response["id"] as int?).toList();

      if (ids.any((id) => null == id)) {
        throw FailureToUploadException("Failed to sync toDos on update \n"
            "ToDo: ${toDos.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }
  }

  @override
  Future<void> delete(ToDo toDo) async {
    if (null == _supabaseClient.auth.currentSession) {
      toDo.toDelete = true;
      update(toDo);
      return;
    }

    try {
      await _supabaseClient.from("toDos").delete().eq("id", toDo.id);
      await _isarClient.writeTxn(() async {
        await _isarClient.toDos.delete(toDo.id);
      });
    } catch (error) {
      throw FailureToDeleteException("Failed to delete ToDo online\n"
          "ToDo: ${toDo.toString()}\n"
          "Time: ${DateTime.now()}\n"
          "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
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

    toDelete.map((ToDo toDo) => toDo.toDelete = true);
    updateBatch(toDelete);
  }

  @override
  Future<void> deleteLocal() async {
    List<int> toDeletes = await getDeleteIds();
    await _isarClient.writeTxn(() async {
      await _isarClient.toDos.deleteAll(toDeletes);
    });
  }

  @override
  Future<void> syncRepo() async {
    if (null == _supabaseClient.auth.currentSession) {
      return fetchRepo();
    }
    List<int> toDeletes = await getDeleteIds();
    if (toDeletes.isNotEmpty) {
      try {
        await _supabaseClient.from("toDos").delete().in_("id", toDeletes);
      } catch (error) {
        throw FailureToDeleteException("Failed to delete toDos on sync.\n"
            "ids: ${toDeletes.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }

    // Get the non-uploaded stuff from Isar.
    List<ToDo> unsyncedToDos = await getUnsynced();

    if (unsyncedToDos.isNotEmpty) {
      List<Map<String, dynamic>> syncEntities = unsyncedToDos.map((toDo) {
        toDo.isSynced = true;
        return toDo.toEntity();
      }).toList();

      final List<Map<String, dynamic>> responses =
          await _supabaseClient.from("toDos").upsert(syncEntities).select("id");

      List<int?> ids =
          responses.map((response) => response["id"] as int?).toList();

      if (ids.any((id) => null == id)) {
        unsyncedToDos.map((toDo) => toDo.isSynced = false);
        throw FailureToUploadException("Failed to sync toDos\n"
            "ToDos: ${unsyncedToDos.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }
    fetchRepo();
  }

  @override
  Future<void> fetchRepo() async {
    late List<Map<String, dynamic>> toDoEntities;

    await Future.delayed(const Duration(seconds: 1)).then((value) async {
      if (null == _supabaseClient.auth.currentSession) {
        return;
      }
      toDoEntities = await _supabaseClient.from("toDos").select();

      if (toDoEntities.isEmpty) {
        return;
      }

      List<ToDo> toDos =
          toDoEntities.map((toDo) => ToDo.fromEntity(entity: toDo)).toList();
      await _isarClient.writeTxn(() async {
        await _isarClient.toDos.clear();
        for (ToDo toDo in toDos) {
          await _isarClient.toDos.put(toDo);
        }
      });
    });
  }

  @override
  Future<ToDo?> getByID({required int id}) async =>
      await _isarClient.toDos.where().idEqualTo(id).findFirst();

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
            .sortByWeight()
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
  Future<int> getMyDayWeight() async => _isarClient.toDos
      .where()
      .myDayEqualTo(true)
      .filter()
      .toDeleteEqualTo(false)
      .completedEqualTo(false)
      .weightProperty()
      .sum();

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
  Future<List<ToDo>> getRepeatables({required DateTime now}) async =>
      _isarClient.toDos
          .where()
          .repeatableEqualTo(true)
          .filter()
          .dueDateLessThan(now)
          .findAll();

  Future<List<int>> getDeleteIds() async =>
      _isarClient.toDos.where().toDeleteEqualTo(true).idProperty().findAll();
  Future<List<ToDo>> getUnsynced() async =>
      _isarClient.toDos.where().isSyncedEqualTo(false).findAll();
}
