import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/task/deadline.dart';
import '../services/isar_service.dart';
import '../services/supabase_service.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/interfaces/repository/deadline_repository.dart';
import '../util/interfaces/sortable.dart';

class DeadlineRepo implements DeadlineRepository {
  DeadlineRepo();

  //DB Clients.
  final SupabaseClient _supabaseClient = SupabaseService.instance.supabaseClient;
  final Isar _isarClient = IsarService.instance.isarClient;



  DateTime get yesterday => DateTime.now().subtract(const Duration(days: 1));
  DateTime get today => DateTime.now();

  @override
  Future<void> create(Deadline deadline) async {
    deadline.isSynced = (null != _supabaseClient.auth.currentSession);
    late int? id;

    await _isarClient.writeTxn(() async {
      id = await _isarClient.deadlines.put(deadline);
    });

    if (null == id) {
      throw FailureToCreateException("Failed to create deadline locally");
    }

    if (null != _supabaseClient.auth.currentSession) {
      Map<String, dynamic> deadlineEntity = deadline.toEntity();
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from("deadlines")
          .insert(deadlineEntity)
          .select("id");
      id = response.last["id"];
      if (null == id) {
        throw FailureToUploadException("Failed to sync deadline on create");
      }
    }
  }

  @override
  Future<void> update(Deadline deadline) async {
    deadline.isSynced = (null != _supabaseClient.auth.currentSession);

    late int? id;
    await _isarClient.writeTxn(() async {
      id = await _isarClient.deadlines.put(deadline);
    });

    if (null == id) {
      throw FailureToUpdateException("Failed to update deadline locally");
    }

    deadline.id = id!;

    if (null != _supabaseClient.auth.currentSession) {
      Map<String, dynamic> deadlineEntity = deadline.toEntity();
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from("deadlines")
          .update(deadlineEntity)
          .select("id");

      id = response.last["id"];

      if (null == id) {
        throw FailureToUploadException("Failed to sync deadline on update");
      }
    }
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
      throw FailureToUpdateException("Failed to update deadlines locally");
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
        throw FailureToUploadException("Failed to sync deadlines on update");
      }
    }
  }

  @override
  Future<void> delete(Deadline deadline) async {
    if (null == _supabaseClient.auth.currentSession) {
      deadline.toDelete = true;
      update(deadline);
      return;
    }

    try {
      await _supabaseClient.from("deadlines").delete().eq("id", deadline.id);
    } catch (error) {
      throw FailureToDeleteException("Failed to delete deadline online");
    }
  }

  @override
  Future<void>deleteFutures({required Deadline deadline}) async {
    List<Deadline> toDelete = await _isarClient.deadlines.where().repeatIDEqualTo(deadline.repeatID).filter().repeatableEqualTo(true).findAll();
    toDelete.map((Deadline deadline) => deadline.toDelete = true);
    updateBatch(toDelete);
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
    if(null == _supabaseClient.auth.currentSession)
      {
        return fetchRepo();
      }

    List<int> toDeletes = await getDeleteIds();
    if (toDeletes.isNotEmpty) {
      try {
        await _supabaseClient.from("deadlines").delete().in_("id", toDeletes);
      } catch (error) {
        // I'm also unsure about this Exception.
        throw FailureToDeleteException("Failed to delete deadlines\n"
            "Connection Status: ${null != _supabaseClient.auth.currentSession}\n"
            "Time: ${DateTime.now()}");
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
            "Connection Status: ${null != _supabaseClient.auth.currentSession}\n"
            "Time: ${DateTime.now()}");
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

  @override
  Future<Deadline?> getByID({required int id}) async =>
      await _isarClient.deadlines.where().notificationIDEqualTo(id).findFirst();

  @override
  Future<List<Deadline>> getRepoList() => _isarClient.deadlines
      .where()
      .toDeleteEqualTo(false)
      .filter()
      .dueDateGreaterThan(yesterday)
      .sortByCustomViewIndex()
      .findAll();

  @override
  Future<List<Deadline>> getRepoListBy(
      {bool showLoading = true, required SortableView<Deadline> sorter}) async {
    switch (sorter.sortMethod) {
      case SortMethod.name:
        if (sorter.descending) {
          return _isarClient.deadlines
              .where()
              .toDeleteEqualTo(false)
              .filter()
              .dueDateGreaterThan(yesterday)
              .sortByNameDesc()
              .findAll();
        } else {
          return _isarClient.deadlines
              .where()
              .toDeleteEqualTo(false)
              .filter()
              .dueDateGreaterThan(yesterday)
              .sortByName()
              .findAll();
        }
      case SortMethod.priority:
        if (sorter.descending) {
          return _isarClient.deadlines
              .where()
              .toDeleteEqualTo(false)
              .filter()
              .dueDateGreaterThan(yesterday)
              .sortByPriorityDesc()
              .findAll();
        } else {
          return _isarClient.deadlines
              .where()
              .toDeleteEqualTo(false)
              .filter()
              .dueDateGreaterThan(yesterday)
              .sortByPriority()
              .findAll();
        }
      case SortMethod.dueDate:
        if (sorter.descending) {
          return _isarClient.deadlines
              .where()
              .toDeleteEqualTo(false)
              .filter()
              .dueDateGreaterThan(yesterday)
              .sortByDueDateDesc()
              .findAll();
        } else {
          return _isarClient.deadlines
              .where()
              .toDeleteEqualTo(false)
              .filter()
              .dueDateGreaterThan(yesterday)
              .sortByDueDate()
              .findAll();
        }
      default:
        return getRepoList();
    }
  }
  @override
  Future<List<Deadline>> getRepeatables({required DateTime now}) async =>
      _isarClient.deadlines
          .where()
          .repeatableEqualTo(true)
          .filter()
          .dueDateLessThan(now)
          .findAll();

  Future<List<int>> getDeleteIds() async => _isarClient.deadlines
      .where()
      .toDeleteEqualTo(true)
      .idProperty()
      .findAll();

  Future<List<Deadline>> getUnsynced() async =>
      _isarClient.deadlines.where().isSyncedEqualTo(false).findAll();

  @override
  Future<List<Deadline>> getOverdues() async => _isarClient.deadlines
      .filter()
      .dueDateLessThan(today)
      .sortByDueDateDesc()
      .findAll();
}
