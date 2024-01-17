import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/task/deadline.dart';
import '../services/isar_service.dart';
import '../services/supabase_service.dart';
import '../util/constants.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/interfaces/i_repeatable.dart';
import '../util/interfaces/repository/model/deadline_repository.dart';
import '../util/interfaces/sortable.dart';

class DeadlineRepo implements DeadlineRepository {
  static final DeadlineRepo _instance = DeadlineRepo._internal();

  static DeadlineRepo get instance => _instance;

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
    deadline.toDelete = true;
    await update(deadline);
  }

  @override
  Future<void> remove(Deadline deadline) async {
    // Delete online
    if (null != _supabaseClient.auth.currentSession) {
      try {
        await _supabaseClient.from("deadlines").delete().eq("id", deadline.id);
      } catch (error) {
        throw FailureToDeleteException("Failed to delete Deadline online\n"
            "Deadline: ${deadline.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }
    // Delete local
    await _isarClient.writeTxn(() async {
      await _isarClient.deadlines.delete(deadline.id);
    });
  }

  @override
  Future<List<int>> emptyTrash() async {
    if (null != _supabaseClient.auth.currentSession) {
      try {
        await _supabaseClient.from("deadlines").delete().eq("toDelete", true);
      } catch (error) {
        throw FailureToDeleteException("Failed to empty trash online\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }
    late List<int> deleteIDs;
    await _isarClient.writeTxn(() async {
      deleteIDs = await _isarClient.deadlines
          .where()
          .toDeleteEqualTo(true)
          .idProperty()
          .findAll();
      await _isarClient.deadlines.deleteAll(deleteIDs);
    });
    return deleteIDs;
  }

  @override
  Future<List<int>> deleteFutures({required IRepeatable deleteFrom}) async {
    List<int> toDelete = await _isarClient.deadlines
        .where()
        .repeatIDEqualTo(deleteFrom.repeatID)
        .filter()
        .startDateGreaterThan(deleteFrom.startDate!)
        .repeatableStateEqualTo(RepeatableState.normal)
        .idProperty()
        .findAll();

    // Online
    if (null != _supabaseClient.auth.currentSession) {
      try {
        await _supabaseClient
            .from("deadlines")
            .delete()
            .inFilter("id", toDelete);
      } catch (error) {
        throw FailureToDeleteException(
            "Failed to delete future events online \n"
            "Deadline: ${deleteFrom.toString()}\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }

    // Offline
    await _isarClient.writeTxn(() async {
      await _isarClient.deadlines.deleteAll(toDelete);
    });

    return toDelete;
  }

  @override
  Future<void> deleteSweep() async {
    List<int> toDeletes = await getDeleteIDs();
    await _isarClient.writeTxn(() async {
      await _isarClient.deadlines.deleteAll(toDeletes);
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
            .from("deadlines")
            .delete()
            .inFilter("id", toDeletes);
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
          await _isarClient.deadlines.put(deadline);
        }
      });
    });
  }

  // Search + Most Recent
  @override
  Future<List<Deadline>> search(
          {required String searchString, bool toDelete = false}) async =>
      await _isarClient.deadlines
          .where()
          .toDeleteEqualTo(toDelete)
          .filter()
          .nameContains(searchString, caseSensitive: false)
          .group((q) => q
              .repeatableStateEqualTo(RepeatableState.normal)
              .or()
              .repeatableStateEqualTo(RepeatableState.delta))
          .limit(5)
          .findAll();

  @override
  Future<List<Deadline>> mostRecent({int limit = 50}) async =>
      await _isarClient.deadlines
          .where()
          .toDeleteEqualTo(false)
          .filter()
          .group((q) => q
              .repeatableStateEqualTo(RepeatableState.normal)
              .or()
              .repeatableStateEqualTo(RepeatableState.delta))
          .sortByLastUpdatedDesc()
          .limit(limit)
          .findAll();

  @override
  Future<Deadline?> getByID({required int id}) async =>
      await _isarClient.deadlines.where().idEqualTo(id).findFirst();

  @override
  Future<List<Deadline>> getRepoList({int limit = 50, int offset = 0}) async =>
      await _isarClient.deadlines
          .where()
          .toDeleteEqualTo(false)
          .filter()
          .group((q) => q
              .repeatableStateEqualTo(RepeatableState.normal)
              .or()
              .repeatableStateEqualTo(RepeatableState.delta))
          .sortByCustomViewIndex()
          .thenByLastUpdatedDesc()
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
          return await _isarClient.deadlines
              .where()
              .toDeleteEqualTo(false)
              .filter()
              .group((q) => q
                  .repeatableStateEqualTo(RepeatableState.normal)
                  .or()
                  .repeatableStateEqualTo(RepeatableState.delta))
              .sortByNameDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        } else {
          return await _isarClient.deadlines
              .where()
              .toDeleteEqualTo(false)
              .filter()
              .group((q) => q
                  .repeatableStateEqualTo(RepeatableState.normal)
                  .or()
                  .repeatableStateEqualTo(RepeatableState.delta))
              .sortByName()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
      case SortMethod.priority:
        if (sorter.descending) {
          return await _isarClient.deadlines
              .where()
              .toDeleteEqualTo(false)
              .filter()
              .group((q) => q
                  .repeatableStateEqualTo(RepeatableState.normal)
                  .or()
                  .repeatableStateEqualTo(RepeatableState.delta))
              .sortByPriorityDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        } else {
          return await _isarClient.deadlines
              .where()
              .toDeleteEqualTo(false)
              .filter()
              .group((q) => q
                  .repeatableStateEqualTo(RepeatableState.normal)
                  .or()
                  .repeatableStateEqualTo(RepeatableState.delta))
              .sortByPriority()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
      case SortMethod.due_date:
        if (sorter.descending) {
          return await _isarClient.deadlines
              .where()
              .toDeleteEqualTo(false)
              .filter()
              .group((q) => q
                  .repeatableStateEqualTo(RepeatableState.normal)
                  .or()
                  .repeatableStateEqualTo(RepeatableState.delta))
              .sortByDueDateDesc()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        } else {
          return await _isarClient.deadlines
              .where()
              .toDeleteEqualTo(false)
              .filter()
              .group((q) => q
                  .repeatableStateEqualTo(RepeatableState.normal)
                  .or()
                  .repeatableStateEqualTo(RepeatableState.delta))
              .sortByDueDate()
              .thenByLastUpdatedDesc()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
      default:
        return getRepoList(limit: limit, offset: offset);
    }
  }

  @override
  Future<List<Deadline>> getDeleted({int limit = 50, int offset = 0}) async =>
      await _isarClient.deadlines
          .where()
          .toDeleteEqualTo(true)
          .filter()
          .group((q) => q
              .repeatableStateEqualTo(RepeatableState.normal)
              .or()
              .repeatableStateEqualTo(RepeatableState.delta))
          .sortByLastUpdatedDesc()
          .offset(offset)
          .limit(limit)
          .findAll();

  @override
  Future<List<Deadline>> getWarnMes({DateTime? now, int limit = 10}) async =>
      await _isarClient.deadlines
          .where()
          .warnMeEqualTo(true)
          .filter()
          .toDeleteEqualTo(false)
          .group((q) => q
              .repeatableStateEqualTo(RepeatableState.normal)
              .or()
              .repeatableStateEqualTo(RepeatableState.delta))
          .dueDateGreaterThan(now ?? Constants.today)
          .sortByDueDate()
          .limit(limit)
          .findAll();

  @override
  Future<List<Deadline>> getRepeatables({DateTime? now}) async =>
      await _isarClient.deadlines
          .where()
          .repeatableEqualTo(true)
          .filter()
          .repeatableStateEqualTo(RepeatableState.normal)
          .originalStartLessThan(now ?? Constants.today)
          .findAll();

  @override
  Future<Deadline?> getNextRepeat(
          {required int repeatID, DateTime? now}) async =>
      await _isarClient.deadlines
          .where()
          .repeatableEqualTo(true)
          .filter()
          .repeatIDEqualTo(repeatID)
          .repeatableStateEqualTo(RepeatableState.normal)
          .originalStartLessThan(now ?? Constants.today)
          .findFirst();

  @override
  Future<Deadline?> getDelta(
          {required DateTime onDate, required int repeatID}) async =>
      await _isarClient.deadlines
          .where()
          .repeatableStateEqualTo(RepeatableState.delta)
          .filter()
          .originalStartEqualTo(onDate)
          .findFirst();

  @override
  Future<List<Deadline>> getDeltas(
          {DateTime? now, required int repeatID}) async =>
      await _isarClient.deadlines
          .where()
          .repeatableStateEqualTo(RepeatableState.delta)
          .filter()
          .repeatIDEqualTo(repeatID)
          .originalStartGreaterThan(now ?? Constants.today)
          .findAll();

  @override
  Future<Deadline?> getTemplate({required int repeatID}) async =>
      await _isarClient.deadlines
          .where()
          .repeatableStateEqualTo(RepeatableState.template)
          .filter()
          .repeatIDEqualTo(repeatID)
          .toDeleteEqualTo(false)
          .findFirst();

  Future<List<int>> getDeleteIDs({DateTime? deleteLimit}) async {
    deleteLimit = deleteLimit ?? Constants.today;
    return await _isarClient.deadlines
        .where()
        .toDeleteEqualTo(true)
        .filter()
        .lastUpdatedLessThan(deleteLimit)
        .idProperty()
        .findAll();
  }

  Future<List<Deadline>> getUnsynced() async =>
      await _isarClient.deadlines.where().isSyncedEqualTo(false).findAll();

  @override
  Future<List<Deadline>> getRange({DateTime? start, DateTime? end}) async {
    start = start ?? DateTime.now().copyWith(day: 1);
    end = end ?? start.copyWith(month: start.month + 1);
    return await _isarClient.deadlines
        .where()
        .dueDateBetween(start, end)
        .filter()
        .toDeleteEqualTo(false)
        .repeatableStateEqualTo(RepeatableState.normal)
        .findAll();
  }

  @override
  Future<List<Deadline>> getUpcoming({int limit = 50, int offset = 0}) async =>
      await _isarClient.deadlines
          .where()
          .dueDateGreaterThan(Constants.today)
          .filter()
          .toDeleteEqualTo(false)
          .group((q) => q
              .repeatableStateEqualTo(RepeatableState.normal)
              .or()
              .repeatableStateEqualTo(RepeatableState.delta))
          .sortByDueDate()
          .thenByLastUpdatedDesc()
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
          .group((q) => q
              .repeatableStateEqualTo(RepeatableState.normal)
              .or()
              .repeatableStateEqualTo(RepeatableState.delta))
          .sortByDueDateDesc()
          .thenByLastUpdatedDesc()
          .offset(offset)
          .limit(limit)
          .findAll();

  DeadlineRepo._internal();
}
