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
  final SupabaseClient _supabaseClient = SupabaseService.supabaseClient;
  final Isar _isarClient = IsarService.isarClient;

  // This may be best moved to the service, or update this value via the service.
  DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));

  @override
  Future<void> create(Deadline deadline) async {
    deadline.isSynced = isDeviceConnected.value;
    late int? id;

    await _isarClient.writeTxn(() async {
      id = await _isarClient.deadlines.put(deadline);
    });

    if (null == id) {
      throw FailureToCreateException("Failed to create deadline locally");
    }

    if (isDeviceConnected.value) {
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
    deadline.isSynced = isDeviceConnected.value;

    late int? id;
    await _isarClient.writeTxn(() async {
      id = await _isarClient.deadlines.put(deadline);
    });

    if (null == id) {
      throw FailureToUpdateException("Failed to update deadline locally");
    }

    deadline.id = id!;

    if (isDeviceConnected.value) {
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
        deadline.isSynced = isDeviceConnected.value;
        id = await _isarClient.deadlines.put(deadline);
        ids.add(id);
      }
    });
    if (ids.any((id) => null == id)) {
      throw FailureToUpdateException("Failed to update deadlines locally");
    }

    if (isDeviceConnected.value) {
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
  Future<void> retry(List<Deadline> deadlines) async {
    late List<int?> ids;
    late int? id;

    await _isarClient.writeTxn(() async {
      ids = List<int?>.empty(growable: true);
      for (Deadline deadline in deadlines) {
        deadline.isSynced = isDeviceConnected.value;
        id = await _isarClient.deadlines.put(deadline);
        ids.add(id);
      }
    });
    if (ids.any((id) => null == id)) {
      throw FailureToUpdateException("Failed to update deadlines locally");
    }

    if (isDeviceConnected.value) {
      ids.clear();
      List<Map<String, dynamic>> deadlineEntities =
          deadlines.map((deadline) => deadline.toEntity()).toList();
      final List<Map<String, dynamic>> responses = await _supabaseClient
          .from("routines")
          .upsert(deadlineEntities)
          .select("id");

      ids = responses.map((response) => response["id"] as int?).toList();

      if (ids.any((id) => null == id)) {
        throw FailureToUploadException("Failed to sync deadlines on update");
      }
    }
  }

  @override
  Future<void> delete(Deadline deadline) async {
    // TODO: NON-ONLINE IMPLEMENTATION, SYNC ISN'T CALLED.
    // if (!user.syncOnline) {
    //   late int? id;
    //   await _isarClient.writeTxn(() async {
    //     id = await _isarClient.deadlines.delete(deadline.id);
    //   });
    //   if (null == id) {
    //     throw FailureToDeleteException("Failed to delete deadline locally");
    //   }
    //   return;
    // }
    if (!isDeviceConnected.value) {
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
  Future<void> syncRepo() async {
    // Get the non-deleted stuff from Isar
    List<int> toDeletes = await getDeleteIds();
    if (toDeletes.isNotEmpty) {
      try {
        await _supabaseClient.from("deadlines").delete().in_("id", toDeletes);
      } catch (error) {
        // I'm also unsure about this Exception.
        throw FailureToDeleteException("Failed to delete deadlines");
      }
    }

    // Get the non-uploaded stuff from Isar.
    List<Deadline> unsynceddeadlines = await getUnsynced();

    if (unsynceddeadlines.isNotEmpty) {
      List<Map<String, dynamic>> syncEntities =
          unsynceddeadlines.map((deadline) {
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
        // Any unsynced stuff will just be caught on next sync.
        // This may not need to be a thing to handle.
        throw FailureToUploadException("Failed to Sync deadlines");
      }
    }
    fetchRepo();
  }

  @override
  Future<void> fetchRepo() async {
    late List<Map<String, dynamic>> deadlineEntities;

    await Future.delayed(const Duration(seconds: 1)).then((value) async {
      if (!isDeviceConnected.value) {
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
        await _isarClient.clear();
        for (Deadline d in deadlines) {
          _isarClient.deadlines.put(d);
        }
      });
    });
  }

  @override
  Future<Deadline> getByID({required int id}) async =>
      await _isarClient.deadlines.where().idEqualTo(id).findAll();

  // Custom view position, reorderable list.
  // CHECK THIS and put in proper query logic pls.
  // POSSIBLY PUT A HARD LIMIT?
  @override
  Future<List<Deadline>> getRepoList() => _isarClient.deadlines
      .filter()
      .toDeleteEqualTo(false)
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
              .filter()
              .toDeleteEqualTo(false)
              .dueDateGreaterThan(yesterday)
              .sortByNameDesc()
              .findAll();
        } else {
          return _isarClient.deadlines
              .filter()
              .toDeleteEqualTo(false)
              .dueDateGreaterThan(yesterday)
              .sortByName()
              .findAll();
        }
      case SortMethod.priority:
        if (sorter.descending) {
          return _isarClient.deadlines
              .filter()
              .toDeleteEqualTo(false)
              .dueDateGreaterThan(yesterday)
              .sortByPriorityDesc()
              .findAll();
        } else {
          return _isarClient.deadlines
              .filter()
              .toDeleteEqualTo(false)
              .dueDateGreaterThan(yesterday)
              .sortByPriority()
              .findAll();
        }
      case SortMethod.dueDate:
        if (sorter.descending) {
          return _isarClient.deadlines
              .filter()
              .toDeleteEqualTo(false)
              .dueDateGreaterThan(yesterday)
              .sortByDueDateDesc()
              .findAll();
        } else {
          return _isarClient.deadlines
              .filter()
              .toDeleteEqualTo(false)
              .dueDateGreaterThan(yesterday)
              .sortByDueDate()
              .findAll();
        }
      default:
        return getRepoList();
    }
  }

  Future<List<int>> getDeleteIds() async =>
      _isarClient.deadlines.filter().toDeleteEqualTo(true).idProperty.findAll();

  Future<List<Deadline>> getUnsynced() async =>
      _isarClient.deadlines.filter().isSyncedEqualTo(false).findAll();

  @override
  Future<List<Deadline>> getOverdues() async => _isarClient.deadlines
      .filter()
      .dueDateLessThan(const DateTime.now())
      .sortByDueDateDesc()
      .findAll();
}
