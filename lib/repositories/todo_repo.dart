import 'dart:async';

import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/task/todo.dart';
import '../services/isar_service.dart';
import '../services/supabase_service.dart';
import '../util/constants.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/interfaces/repository/model/todo_repository.dart';
import '../util/interfaces/sortable.dart';

class ToDoRepo implements ToDoRepository {
  // TODO: MAKE THESE IMPLEMENTATIONS SINGLETONS.

  static final ToDoRepo _instance = ToDoRepo._internal();

  static ToDoRepo get instance => _instance;

  final SupabaseClient _supabaseClient =
      SupabaseService.instance.supabaseClient;
  final Isar _isarClient = IsarService.instance.isarClient;

  @override
  Future<ToDo> create(ToDo toDo) async {
    toDo.isSynced = (null != _supabaseClient.auth.currentSession);

    late int? id;
    await _isarClient.writeTxn(() async {
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

    return toDo;
  }

  @override
  Future<ToDo> update(ToDo toDo) async {
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
    return toDo;
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
          (toDos).map((toDo) => toDo.toEntity()).toList();
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
    toDo.toDelete = true;
    await update(toDo);
  }

  @override
  Future<void> remove(ToDo toDo) async {
    // Delete online
    if (null != _supabaseClient.auth.currentSession) {
      try {
        await _supabaseClient.from("toDos").delete().eq("id", toDo.id);
      } catch (error) {
        throw FailureToDeleteException("Failed to delete ToDo online\n"
            "ToDo: ${toDo.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }
    // Delete local
    await _isarClient.writeTxn(() async {
      await _isarClient.toDos.delete(toDo.id);
    });
  }

  @override
  Future<List<int>> emptyTrash() async {
    if (null != _supabaseClient.auth.currentSession) {
      try {
        await _supabaseClient.from("toDos").delete().eq("toDelete", true);
      } catch (error) {
        throw FailureToDeleteException("Failed to empty trash online\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }

    late List<int> deleteIDs;

    await _isarClient.writeTxn(() async {
      deleteIDs = await _isarClient.toDos
          .where()
          .toDeleteEqualTo(true)
          .idProperty()
          .findAll();
      await _isarClient.toDos.deleteAll(deleteIDs);
    });
    return deleteIDs;
  }

  @override
  Future<List<int>> deleteFutures({required ToDo deleteFrom}) async {
    List<int> toDelete = await _isarClient.toDos
        .where()
        .repeatIDEqualTo(deleteFrom.repeatID)
        .filter()
        .startDateGreaterThan(deleteFrom.startDate!)
        .idProperty()
        .findAll();

    // Online
    if (null != _supabaseClient.auth.currentSession) {
      try {
        await _supabaseClient.from("toDos").delete().inFilter("id", toDelete);
      } catch (error) {
        throw FailureToDeleteException(
            "Failed to delete future events online \n"
            "ToDo: ${deleteFrom.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }

    // Offline
    await _isarClient.writeTxn(() async {
      await _isarClient.toDos.deleteAll(toDelete);
    });

    return toDelete;
  }

  // TODO: refactor this to take a time limit?.
  @override
  Future<void> deleteSweep() async {
    List<int> toDeletes = await getDeleteIDs();
    await _isarClient.writeTxn(() async {
      await _isarClient.toDos.deleteAll(toDeletes);
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
        await _supabaseClient.from("toDos").delete().inFilter("id", toDeletes);
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
  Future<List<ToDo>> search(
          {required String searchString, bool toDelete = false}) async =>
      await _isarClient.toDos
          .where()
          .toDeleteEqualTo(toDelete)
          .filter()
          .nameContains(searchString, caseSensitive: false)
          .limit(5)
          .findAll();

  @override
  Future<List<ToDo>> mostRecent({int limit = 50}) async =>
      await _isarClient.toDos
          .where()
          .toDeleteEqualTo(false)
          .sortByLastUpdatedDesc()
          .limit(limit)
          .findAll();

  @override
  Future<ToDo?> getByID({required int id}) async =>
      await _isarClient.toDos.where().idEqualTo(id).findFirst();

  @override
  Future<List<ToDo>> getRepoList(
          {int limit = 50, int offset = 0, bool completed = false}) async =>
      await _isarClient.toDos
          .where()
          .completedEqualTo(completed)
          .filter()
          .toDeleteEqualTo(false)
          .repeatableStateEqualTo(RepeatableState.normal)
          .sortByCustomViewIndex()
          .thenByLastUpdatedDesc()
          .offset(offset)
          .limit(limit)
          .findAll();

  @override
  Future<List<ToDo>> getRepoListBy(
      {int limit = 50,
      int offset = 0,
      bool completed = false,
      required SortableView<ToDo> sorter}) async {
    switch (sorter.sortMethod) {
      case SortMethod.name:
        if (sorter.descending) {
          return await _isarClient.toDos
              .where()
              .completedEqualTo(completed)
              .filter()
              .toDeleteEqualTo(false)
              .repeatableStateEqualTo(RepeatableState.normal)
              .sortByNameDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
        return await _isarClient.toDos
            .where()
            .completedEqualTo(completed)
            .filter()
            .toDeleteEqualTo(false)
            .repeatableStateEqualTo(RepeatableState.normal)
            .sortByName()
            .thenByLastUpdatedDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
      case SortMethod.due_date:
        if (sorter.descending) {
          return await _isarClient.toDos
              .where()
              .completedEqualTo(completed)
              .filter()
              .toDeleteEqualTo(false)
              .repeatableStateEqualTo(RepeatableState.normal)
              .sortByDueDateDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
        return await _isarClient.toDos
            .where()
            .completedEqualTo(completed)
            .filter()
            .toDeleteEqualTo(false)
            .repeatableStateEqualTo(RepeatableState.normal)
            .sortByDueDate()
            .thenByLastUpdatedDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
      case SortMethod.weight:
        if (sorter.descending) {
          return await _isarClient.toDos
              .where()
              .completedEqualTo(completed)
              .filter()
              .toDeleteEqualTo(false)
              .repeatableStateEqualTo(RepeatableState.normal)
              .sortByWeightDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
        return await _isarClient.toDos
            .where()
            .completedEqualTo(completed)
            .filter()
            .toDeleteEqualTo(false)
            .repeatableStateEqualTo(RepeatableState.normal)
            .sortByWeight()
            .thenByLastUpdatedDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
      case SortMethod.priority:
        if (sorter.descending) {
          return await _isarClient.toDos
              .where()
              .completedEqualTo(completed)
              .filter()
              .toDeleteEqualTo(false)
              .repeatableStateEqualTo(RepeatableState.normal)
              .sortByPriorityDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
        return await _isarClient.toDos
            .where()
            .completedEqualTo(completed)
            .filter()
            .toDeleteEqualTo(false)
            .repeatableStateEqualTo(RepeatableState.normal)
            .sortByPriority()
            .thenByLastUpdatedDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
      case SortMethod.duration:
        if (sorter.descending) {
          return await _isarClient.toDos
              .where()
              .completedEqualTo(completed)
              .filter()
              .toDeleteEqualTo(false)
              .repeatableStateEqualTo(RepeatableState.normal)
              .sortByRealDurationDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
        return await _isarClient.toDos
            .where()
            .completedEqualTo(completed)
            .filter()
            .toDeleteEqualTo(false)
            .repeatableStateEqualTo(RepeatableState.normal)
            .sortByRealDuration()
            .thenByLastUpdatedDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
      default:
        return getRepoList(limit: limit, offset: offset, completed: completed);
    }
  }

  @override
  Future<List<ToDo>> getDeleted({int limit = 50, int offset = 0}) async =>
      await _isarClient.toDos
          .where()
          .toDeleteEqualTo(true)
          .filter()
          .repeatableStateEqualTo(RepeatableState.normal)
          .sortByLastUpdatedDesc()
          .offset(offset)
          .limit(limit)
          .findAll();

  @override
  Future<List<ToDo>> getCompleted(
          {required SortableView<ToDo> sorter,
          int limit = 50,
          int offset = 0}) async =>
      await getRepoListBy(
          sorter: sorter, limit: limit, offset: offset, completed: true);

  @override
  Future<List<ToDo>> getMyDay(
      {required SortableView<ToDo> sorter,
      int limit = 50,
      int offset = 0}) async {
    switch (sorter.sortMethod) {
      case SortMethod.name:
        if (sorter.descending) {
          return await _isarClient.toDos
              .where()
              .completedEqualTo(false)
              .filter()
              .myDayEqualTo(true)
              .toDeleteEqualTo(false)
              .repeatableStateEqualTo(RepeatableState.normal)
              .sortByNameDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
        return await _isarClient.toDos
            .where()
            .completedEqualTo(false)
            .filter()
            .myDayEqualTo(true)
            .toDeleteEqualTo(false)
            .repeatableStateEqualTo(RepeatableState.normal)
            .sortByName()
            .thenByLastUpdatedDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
      case SortMethod.due_date:
        if (sorter.descending) {
          return await _isarClient.toDos
              .where()
              .completedEqualTo(false)
              .filter()
              .myDayEqualTo(true)
              .toDeleteEqualTo(false)
              .repeatableStateEqualTo(RepeatableState.normal)
              .sortByDueDateDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
        return await _isarClient.toDos
            .where()
            .completedEqualTo(false)
            .filter()
            .myDayEqualTo(true)
            .toDeleteEqualTo(false)
            .repeatableStateEqualTo(RepeatableState.normal)
            .sortByDueDate()
            .thenByLastUpdatedDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
      case SortMethod.weight:
        if (sorter.descending) {
          return await _isarClient.toDos
              .where()
              .completedEqualTo(false)
              .filter()
              .myDayEqualTo(true)
              .toDeleteEqualTo(false)
              .repeatableStateEqualTo(RepeatableState.normal)
              .sortByWeightDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
        return await _isarClient.toDos
            .where()
            .completedEqualTo(false)
            .filter()
            .myDayEqualTo(true)
            .toDeleteEqualTo(false)
            .repeatableStateEqualTo(RepeatableState.normal)
            .sortByWeight()
            .thenByLastUpdatedDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
      case SortMethod.priority:
        if (sorter.descending) {
          return await _isarClient.toDos
              .where()
              .completedEqualTo(false)
              .filter()
              .myDayEqualTo(true)
              .toDeleteEqualTo(false)
              .repeatableStateEqualTo(RepeatableState.normal)
              .sortByPriorityDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
        return await _isarClient.toDos
            .where()
            .completedEqualTo(false)
            .filter()
            .myDayEqualTo(true)
            .toDeleteEqualTo(false)
            .repeatableStateEqualTo(RepeatableState.normal)
            .sortByPriority()
            .thenByLastUpdatedDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
      case SortMethod.duration:
        if (sorter.descending) {
          return await _isarClient.toDos
              .where()
              .completedEqualTo(false)
              .filter()
              .myDayEqualTo(true)
              .toDeleteEqualTo(false)
              .repeatableStateEqualTo(RepeatableState.normal)
              .sortByRealDurationDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
        return await _isarClient.toDos
            .where()
            .completedEqualTo(false)
            .filter()
            .myDayEqualTo(true)
            .toDeleteEqualTo(false)
            .repeatableStateEqualTo(RepeatableState.normal)
            .sortByRealDuration()
            .thenByLastUpdatedDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
      default:
        return await _isarClient.toDos
            .where()
            .completedEqualTo(false)
            .filter()
            .myDayEqualTo(true)
            .toDeleteEqualTo(false)
            .repeatableStateEqualTo(RepeatableState.normal)
            .sortByCustomViewIndex()
            .thenByLastUpdatedDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
    }
  }

  @override
  Future<int> getMyDayWeight({int limit = 50}) async => await _isarClient.toDos
      .where()
      .myDayEqualTo(true)
      .filter()
      .toDeleteEqualTo(false)
      .repeatableStateEqualTo(RepeatableState.normal)
      .completedEqualTo(false)
      .limit(limit)
      .weightProperty()
      .sum();

  @override
  Future<List<ToDo>> getRepoByGroupID(
          {required int groupID, int limit = 50, int offset = 0}) async =>
      await _isarClient.toDos
          .where()
          .groupIDEqualTo(groupID)
          .filter()
          .toDeleteEqualTo(false)
          .repeatableStateEqualTo(RepeatableState.normal)
          .sortByGroupIndex()
          .thenByLastUpdatedDesc()
          .offset(offset)
          .limit(limit)
          .findAll();

  // This needs to capture "deleted" deltas.
  @override
  Future<List<ToDo>> getRepeatables({DateTime? now}) async =>
      await _isarClient.toDos
          .where()
          .repeatableEqualTo(true)
          .filter()
          .repeatableStateEqualTo(RepeatableState.normal)
          .originalStartLessThan(now ?? Constants.today)
          .findAll();

  @override
  Future<ToDo?> getDelta(
          {required DateTime onDate, required int repeatID}) async =>
      await _isarClient.toDos
          .where()
          .repeatableStateEqualTo(RepeatableState.delta)
          .filter()
          .originalStartEqualTo(onDate)
          .findFirst();

  @override
  Future<ToDo?> getTemplate({required int repeatID}) async =>
      await _isarClient.toDos
          .where()
          .repeatableStateEqualTo(RepeatableState.template)
          .filter()
          .repeatIDEqualTo(repeatID)
          .toDeleteEqualTo(false)
          .findFirst();

  // TODO: Migrate to other repositories
  Future<List<int>> getDeleteIDs({DateTime? deleteLimit}) async {
    deleteLimit = deleteLimit ?? Constants.today;
    return await _isarClient.toDos
        .where()
        .toDeleteEqualTo(true)
        .filter()
        .lastUpdatedLessThan(deleteLimit)
        .idProperty()
        .findAll();
  }

  Future<List<ToDo>> getUnsynced() async =>
      await _isarClient.toDos.where().isSyncedEqualTo(false).findAll();

  @override
  Future<List<ToDo>> getRange({DateTime? start, DateTime? end}) async {
    start = start ?? DateTime.now().copyWith(day: 1);
    end = end ?? start.copyWith(month: start.month + 1);
    return await _isarClient.toDos
        .where()
        .dueDateBetween(start, end)
        .filter()
        .toDeleteEqualTo(false)
        .repeatableStateEqualTo(RepeatableState.normal)
        .findAll();
  }

  @override
  Future<List<ToDo>> getUpcoming({int limit = 50, int offset = 0}) async =>
      await _isarClient.toDos
          .where()
          .dueDateGreaterThan(Constants.today)
          .filter()
          .toDeleteEqualTo(false)
          .repeatableStateEqualTo(RepeatableState.normal)
          .sortByDueDate()
          .thenByLastUpdatedDesc()
          .offset(offset)
          .limit(limit)
          .findAll();

  @override
  Future<List<ToDo>> getOverdues({int limit = 50, int offset = 0}) async =>
      await _isarClient.toDos
          .where()
          .dueDateLessThan(Constants.today)
          .filter()
          .toDeleteEqualTo(false)
          .repeatableStateEqualTo(RepeatableState.normal)
          .sortByDueDateDesc()
          .thenByLastUpdatedDesc()
          .offset(offset)
          .limit(limit)
          .findAll();

  @override
  Future<int> getGroupToDoCount({required int groupID}) async =>
      await _isarClient.toDos
          .where()
          .groupIDEqualTo(groupID)
          .filter()
          .toDeleteEqualTo(false)
          .repeatableStateEqualTo(RepeatableState.normal)
          .count();

  ToDoRepo._internal();
}
