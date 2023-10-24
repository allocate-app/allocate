import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/task/group.dart';
import '../services/isar_service.dart';
import '../services/supabase_service.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/interfaces/repository/model/group_repository.dart';
import '../util/interfaces/sortable.dart';

class GroupRepo implements GroupRepository {
  final SupabaseClient _supabaseClient =
      SupabaseService.instance.supabaseClient;
  final Isar _isarClient = IsarService.instance.isarClient;

  @override
  Future<Group> create(Group group) async {
    group.isSynced = (null != _supabaseClient.auth.currentSession);
    late int? id;

    await _isarClient.writeTxn(() async {
      id = await _isarClient.groups.put(group);
    });

    if (null == id) {
      throw FailureToCreateException("Failed to create group locally\n"
          "Group: ${group.toString()}\n"
          "Time: ${DateTime.now()}\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (null != _supabaseClient.auth.currentSession) {
      Map<String, dynamic> groupEntity = group.toEntity();
      final List<Map<String, dynamic>> response =
          await _supabaseClient.from("groups").insert(groupEntity).select("id");
      id = response.last["id"];
      if (null == id) {
        throw FailureToUploadException("Failed to sync group on create");
      }
    }
    return group;
  }

  @override
  Future<Group> update(Group group) async {
    group.isSynced = (null != _supabaseClient.auth.currentSession);

    late int? id;
    await _isarClient.writeTxn(() async {
      id = await _isarClient.groups.put(group);
    });

    if (null == id) {
      throw FailureToUpdateException("Failed to update deadline locally\n"
          "Group: ${group.toString()}\n"
          "Time: ${DateTime.now()}\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (null != _supabaseClient.auth.currentSession) {
      Map<String, dynamic> groupEntity = group.toEntity();
      final List<Map<String, dynamic>> response =
          await _supabaseClient.from("groups").update(groupEntity).select("id");

      id = response.last["id"];

      if (null == id) {
        throw FailureToUploadException("Failed to sync deadline on update\n"
            "Group: ${group.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }
    return group;
  }

  @override
  Future<void> updateBatch(List<Group> groups) async {
    late List<int?> ids;
    late int? id;
    await _isarClient.writeTxn(() async {
      ids = List<int?>.empty(growable: true);
      for (Group group in groups) {
        group.isSynced = (null != _supabaseClient.auth.currentSession);
        id = await _isarClient.groups.put(group);
        ids.add(id);
      }
    });
    if (ids.any((id) => null == id)) {
      throw FailureToUpdateException("Failed to update groups locally\n"
          "Groups: ${groups.toString()}\n"
          "Time: ${DateTime.now()}\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (null != _supabaseClient.auth.currentSession) {
      ids.clear();
      List<Map<String, dynamic>> groupEntities =
          groups.map((group) => group.toEntity()).toList();
      for (Map<String, dynamic> groupEntity in groupEntities) {
        final List<Map<String, dynamic>> response = await _supabaseClient
            .from("groups")
            .update(groupEntity)
            .select("id");
        id = response.last["id"];
        ids.add(id);
      }
      if (ids.any((id) => null == id)) {
        throw FailureToUploadException("Failed to sync groups on update\n"
            "Groups: ${groups.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }
  }

  @override
  Future<void> delete(Group group) async {
    if (null == _supabaseClient.auth.currentSession) {
      group.toDelete = true;
      await update(group);
      return;
    }

    try {
      await _supabaseClient.from("groups").delete().eq("id", group.id);
    } catch (error) {
      throw FailureToDeleteException("Failed to delete group online\n"
          "Group: ${group.toString()}\n"
          "Time: ${DateTime.now()}\n\n"
          "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
    }
  }

  @override
  Future<void> deleteLocal() async {
    List<int> toDeletes = await getDeleteIds();
    await _isarClient.writeTxn(() async {
      await _isarClient.groups.deleteAll(toDeletes);
    });
  }

  @override
  Future<void> syncRepo() async {
    if (null == _supabaseClient.auth.currentSession) {
      return fetchRepo();
    }
    // Get the non-deleted stuff from Isar
    List<int> toDeletes = await getDeleteIds();
    if (toDeletes.isNotEmpty) {
      try {
        await _supabaseClient.from("groups").delete().in_("id", toDeletes);
      } catch (error) {
        // I'm also unsure about this Exception.
        throw FailureToDeleteException("Failed to delete groups on sync\n"
            "Group: ${toDeletes.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }

    // Get the non-uploaded stuff from Isar.
    List<Group> unsyncedGroups = await getUnsynced();

    if (unsyncedGroups.isNotEmpty) {
      List<Map<String, dynamic>> syncEntities = unsyncedGroups.map((group) {
        group.isSynced = true;
        return group.toEntity();
      }).toList();

      final List<Map<String, dynamic>> responses = await _supabaseClient
          .from("groups")
          .upsert(syncEntities)
          .select("id");

      List<int?> ids =
          responses.map((response) => response["id"] as int?).toList();

      if (ids.any((id) => null == id)) {
        throw FailureToUploadException("Failed to sync groups\n"
            "Groups: ${unsyncedGroups.toString()}\n"
            "Time: ${DateTime.now()}\n\n"
            "Supabase Open: ${null != _supabaseClient.auth.currentSession}");
      }
    }
    // Fetch from supabase.
    fetchRepo();
  }

  @override
  Future<void> fetchRepo() async {
    late List<Map<String, dynamic>> groupEntities;

    await Future.delayed(const Duration(seconds: 1)).then((value) async {
      if (null == _supabaseClient.auth.currentSession) {
        return;
      }
      groupEntities = await _supabaseClient.from("groups").select();

      if (groupEntities.isEmpty) {
        return;
      }

      List<Group> groups = groupEntities
          .map((group) => Group.fromEntity(entity: group))
          .toList();
      await _isarClient.writeTxn(() async {
        await _isarClient.groups.clear();
        for (Group group in groups) {
          _isarClient.groups.put(group);
        }
      });
    });
  }

  @override
  Future<List<Group>> search({required String searchString}) async =>
      await _isarClient.groups
          .filter()
          .nameContains(searchString, caseSensitive: false)
          .limit(5)
          .findAll();

  @override
  Future<List<Group>> mostRecent({int limit = 50}) async =>
      await _isarClient.groups
          .where()
          .toDeleteEqualTo(false)
          .sortByLastUpdatedDesc()
          .limit(limit)
          .findAll();

  @override
  Future<Group?> getByID({required int id}) async => await _isarClient.groups
      .where()
      .idEqualTo(id)
      .filter()
      .toDeleteEqualTo(false)
      .findFirst();

  // Basic query logic.
  @override
  Future<List<Group>> getRepoList({int limit = 50, int offset = 0}) =>
      _isarClient.groups
          .where()
          .toDeleteEqualTo(false)
          .sortByCustomViewIndex()
          .thenByLastUpdatedDesc()
          .offset(offset)
          .limit(limit)
          .findAll();

  @override
  Future<List<Group>> getRepoListBy(
      {required SortableView<Group> sorter,
      int limit = 50,
      int offset = 0}) async {
    switch (sorter.sortMethod) {
      case SortMethod.name:
        if (sorter.descending) {
          return _isarClient.groups
              .where()
              .toDeleteEqualTo(false)
              .sortByNameDesc()
              .thenByLastUpdated()
              .offset(offset)
              .limit(limit)
              .findAll();
        } else {
          return _isarClient.groups
              .where()
              .toDeleteEqualTo(false)
              .sortByName()
              .thenByLastUpdated()
              .offset(offset)
              .limit(limit)
              .findAll();
        }
      default:
        return getRepoList(limit: limit, offset: offset);
    }
  }

  Future<List<int>> getDeleteIds() async =>
      _isarClient.groups.filter().toDeleteEqualTo(true).idProperty().findAll();

  Future<List<Group>> getUnsynced() async =>
      _isarClient.groups.filter().isSyncedEqualTo(false).findAll();
}
