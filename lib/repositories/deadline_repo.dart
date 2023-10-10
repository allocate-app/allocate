import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/task/deadline.dart';
import '../services/isar_service.dart';
import '../services/supabase_service.dart';
import '../util/constants.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/interfaces/repository/model/deadline_repository.dart';
import '../util/interfaces/sortable.dart';

class DeadlineRepo implements DeadlineRepository {
  //DB Clients.
  final SupabaseClient _supabaseClient =
      SupabaseService.instance.supabaseClient;
  final Isar _isarClient = IsarService.instance.isarClient;

  @override
  Future<Deadline> create(Deadline deadline) async {
    deadline.isSynced = (null != _supabaseClient.auth.currentSession);
    late int? id;

    await _isarClient.writeTxn(() async {
      id = await _isarClient.deadlines.put(deadline);
    });

    if (null == id) {
      throw FailureToCreateException("Failed to create deadline locally\n"
          "Deadline: ${deadline.toString()}\n"
          "Time: $Constants.today\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (null != _supabaseClient.auth.currentSession) {
      Map<String, dynamic> deadlineEntity = deadline.toEntity();
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from("deadlines")
          .insert(deadlineEntity)
          .select("id");
      id = response.last["id"];
      if (null == id) {
        throw FailureToUploadException("Failed to sync deadline on create\n"
            "Deadline: ${deadline.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }
    return deadline;
  }

  @override
  Future<Deadline> update(Deadline deadline) async {
    deadline.isSynced = (null != _supabaseClient.auth.currentSession);

    late int? id;
    await _isarClient.writeTxn(() async {
      id = await _isarClient.deadlines.put(deadline);
    });

    if (null == id) {
      throw FailureToUpdateException("Failed to update deadline locally\n"
          "Deadline: ${deadline.toString()}\n"
          "Time: $Constants.today\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (null != _supabaseClient.auth.currentSession) {
      Map<String, dynamic> deadlineEntity = deadline.toEntity();
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from("deadlines")
          .update(deadlineEntity)
          .select("id");

      id = response.last["id"];

      if (null == id) {
        throw FailureToUploadException("Failed to sync deadline on update\n"
            "Deadline: ${deadline.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }
    return deadline;
  }

  @override
  Future<void> updateBatch(List<Deadline> deadlines) async {
    late List<int?> ids;
    late int? id;
    await _isarClient.writeTxn(() async {
      ids = List<int?>.empty(growable: true);
      for (Deadline deadline in deadlines) {
        deadline.isSynced = (null != _supabaseClient.auth.currentSession);
        id = await _isarClient.deadlines.put(deadline);
        ids.add(id);
      }
    });
    if (ids.any((id) => null == id)) {
      throw FailureToUpdateException("Failed to update deadlines locally\n"
          "Deadline: ${deadlines.toString()}\n"
          "Time: $Constants.today\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (null != _supabaseClient.auth.currentSession) {
      ids.clear();
      List<Map<String, dynamic>> deadlineEntities =
          deadlines.map((deadline) => deadline.toEntity()).toList();
      for (Map<String, dynamic> deadlineEntity in deadlineEntities) {
        final List<Map<String, dynamic>> response = await _supabaseClient
            .from("deadlines")
            .update(deadlineEntity)
            .select("id");
        id = response.last["id"];
        ids.add(id);
      }
      if (ids.any((id) => null == id)) {
        throw FailureToUploadException("Failed to sync deadlines on update\n"
            "Deadline: ${deadlines.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }
  }

  @override
  Future<void> delete(Deadline deadline) async {
    if (null == _supabaseClient.auth.currentSession) {
      deadline.toDelete = true;
      await update(deadline);
      return;
    }

    try {
      await _supabaseClient.from("deadlines").delete().eq("id", deadline.id);
    } catch (error) {
      throw FailureToDeleteException("Failed to delete deadline online\n"
          "Deadline: ${deadline.toString()}\n"
          "Time: ${DateTime.now()}\n\n"
          "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
    }
  }

  @override
  Future<List<Deadline>> deleteFutures({required Deadline deleteFrom}) async {
    List<Deadline> toDelete = await _isarClient.deadlines
        .where()
        .repeatIDEqualTo(deleteFrom.repeatID)
        .filter()
        .dueDateGreaterThan(deleteFrom.dueDate)
        .findAll();

    // This is to prevent a race condition & accidentally deleting a notification.
    toDelete.remove(deleteFrom);
    toDelete.map((Deadline deadline) => deadline.toDelete = true).toList();

    await updateBatch(toDelete);
    return toDelete;
  }

  @override
  Future<void> deleteLocal() async {
    List<int> toDeletes = await getDeleteIds();
    await _isarClient.writeTxn(() async {
      await _isarClient.deadlines.deleteAll(toDeletes);
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
        await _supabaseClient.from("deadlines").delete().in_("id", toDeletes);
      } catch (error) {
        // I'm also unsure about this Exception.
        throw FailureToDeleteException("Failed to delete deadlines\n"
            "ids: ${toDeletes.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }

    // Get the non-uploaded stuff from Isar.
    List<Deadline> unsyncedDeadlines = await getUnsynced();

    if (unsyncedDeadlines.isNotEmpty) {
      List<Map<String, dynamic>> syncEntities =
          unsyncedDeadlines.map((deadline) {
        deadline.isSynced = true;
        return deadline.toEntity();
      }).toList();

      final List<Map<String, dynamic>> responses = await _supabaseClient
          .from("deadlines")
          .upsert(syncEntities)
          .select("id");

      List<int?> ids =
          responses.map((response) => response["id"] as int?).toList();

      if (ids.any((id) => null == id)) {
        throw FailureToUploadException("Failed to Sync deadlines\n"
            "deadlines: ${unsyncedDeadlines.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }
    fetchRepo();
  }

  @override
  Future<void> fetchRepo() async {
    late List<Map<String, dynamic>> deadlineEntities;

    await Future.delayed(const Duration(seconds: 1)).then((value) async {
      if (null == _supabaseClient.auth.currentSession) {
        return;
      }
      deadlineEntities = await _supabaseClient.from("deadlines").select();

      if (deadlineEntities.isEmpty) {
        return;
      }

      List<Deadline> deadlines = deadlineEntities
          .map((deadline) => Deadline.fromEntity(entity: deadline))
          .toList();
      await _isarClient.writeTxn(() async {
        await _isarClient.deadlines.clear();
        for (Deadline deadline in deadlines) {
          _isarClient.deadlines.put(deadline);
        }
      });
    });
  }

  // Search + Most Recent
  @override
  Future<List<Deadline>> search({required String searchString}) async =>
      await _isarClient.deadlines
          .filter()
          .nameContains(searchString, caseSensitive: false)
          .limit(5)
          .findAll();

  @override
  Future<List<Deadline>> mostRecent({int limit = 50}) async =>
      await _isarClient.deadlines
          .where()
          .sortByLastUpdatedDesc()
          .limit(limit)
          .findAll();

  @override
  Future<Deadline?> getByID({required int id}) async =>
      await _isarClient.deadlines.where().idEqualTo(id).findFirst();

  @override
  Future<List<Deadline>> getRepoList({int limit = 50, int offset = 0}) =>
      _isarClient.deadlines
          .where()
          .toDeleteEqualTo(false)
          .sortByCustomViewIndex()
          .thenByLastUpdated()
          .offset(offset)
          .limit(limit)
          .findAll();

  @override
  Future<List<Deadline>> getRepoListBy(
      {int limit = 50,
      int offset = 0,
      required SortableView<Deadline> sorter}) async {
    switch (sorter.sortMethod) {
      case SortMethod.name:
        if (sorter.descending) {
          return _isarClient.deadlines
              .where()
              .toDeleteEqualTo(false)
              .sortByNameDesc()
              .thenByLastUpdated()
              .offset(offset)
              .limit(limit)
              .findAll();
        } else {
          return _isarClient.deadlines
              .where()
              .toDeleteEqualTo(false)
              .sortByName()
              .thenByLastUpdated()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
      case SortMethod.priority:
        if (sorter.descending) {
          return _isarClient.deadlines
              .where()
              .toDeleteEqualTo(false)
              .sortByPriorityDesc()
              .thenByLastUpdated()
              .offset(offset)
              .limit(limit)
              .findAll();
        } else {
          return _isarClient.deadlines
              .where()
              .toDeleteEqualTo(false)
              .sortByPriority()
              .thenByLastUpdated()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
      case SortMethod.due_date:
        if (sorter.descending) {
          return _isarClient.deadlines
              .where()
              .toDeleteEqualTo(false)
              .sortByDueDateDesc()
              .thenByLastUpdated()
              .offset(offset)
              .limit(limit)
              .findAll();
        } else {
          return _isarClient.deadlines
              .where()
              .toDeleteEqualTo(false)
              .sortByDueDate()
              .thenByLastUpdated()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
      default:
        return getRepoList(limit: limit, offset: offset);
    }
  }

  @override
  Future<List<Deadline>> getWarnMes({DateTime? now, int limit = 10}) async =>
      _isarClient.deadlines
          .where()
          .warnMeEqualTo(true)
          .filter()
          .toDeleteEqualTo(false)
          .dueDateGreaterThan(now ?? Constants.today)
          .sortByDueDate()
          .limit(limit)
          .findAll();

  @override
  Future<List<Deadline>> getRepeatables({DateTime? now}) async =>
      _isarClient.deadlines
          .where()
          .repeatableEqualTo(true)
          .filter()
          .toDeleteEqualTo(false)
          .dueDateLessThan(now ?? Constants.today)
          .findAll();

  Future<List<int>> getDeleteIds() async => _isarClient.deadlines
      .where()
      .toDeleteEqualTo(true)
      .idProperty()
      .findAll();

  Future<List<Deadline>> getUnsynced() async =>
      _isarClient.deadlines.where().isSyncedEqualTo(false).findAll();

  @override
  Future<List<Deadline>> getRange({DateTime? start, DateTime? end}) async {
    start = start ?? DateTime.now().copyWith(day: 1);
    end = end ?? start.copyWith(month: start.month + 1);
    return await _isarClient.deadlines
        .where()
        .dueDateBetween(start, end)
        .filter()
        .toDeleteEqualTo(false)
        .findAll();
  }

  @override
  Future<List<Deadline>> getUpcoming({int limit = 50, int offset = 0}) async =>
      _isarClient.deadlines
          .where()
          .dueDateGreaterThan(Constants.today)
          .filter()
          .toDeleteEqualTo(false)
          .sortByDueDate()
          .thenByLastUpdated()
          .offset(offset)
          .limit(limit)
          .findAll();

  @override
  Future<List<Deadline>> getOverdues({int limit = 50, int offset = 0}) async =>
      _isarClient.deadlines
          .where()
          .dueDateLessThan(Constants.today)
          .filter()
          .toDeleteEqualTo(false)
          .sortByDueDateDesc()
          .thenByLastUpdated()
          .offset(offset)
          .limit(limit)
          .findAll();
}
