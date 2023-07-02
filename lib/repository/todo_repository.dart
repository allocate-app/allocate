import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/isar_service.dart';
import '../services/supabase_service.dart';
//TODO: Check this and determine how best to handle internet connection.
import '../main.dart';
import '../model/task/todo.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/interfaces/repository.dart';
import '../util/interfaces/sortable.dart';
import '../util/sorters/todo_sorter.dart';

class ToDoRepository implements Repository<ToDo>
{
  final SupabaseClient _supabaseClient = SupabaseService.supabaseClient;
  final Isar _isarClient = IsarService.isarClient;

  @override
  @override
  Future<void> create(ToDo todo) async
  {
    todo.isSynced = isDeviceConnected.value;

    late int? id;
    await _isarClient.writeTxn(() async {
      //This will require to be corrected once db is generated.
      id = await _isarClient.todos.put(todo);
    }
    );

    if(null == id)
    {
      throw FailureToCreateException("Failed to create ToDo locally");
    }

    todo.id = id!;

    if(isDeviceConnected.value)
    {
      Map<String, dynamic> todoEntity = todo.toEntity();
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from("todos")
          .insert(todoEntity)
          .select("id");

      id = response.last["id"];

      if(null == id)
      {
        throw FailureToUploadException("Failed to sync ToDo on create");
      }
    }
  }

  @override
  Future<void> update(ToDo t) async {
    t.isSynced = isDeviceConnected.value;

    // This is just for error checking.
    late int? id;
    await _isarClient.writeTxn(() async {
      id = await _isarClient.todos.put(t);
    });

    if(null == id)
    {
      throw FailureToUpdateException("Failed to update todo locally");
    }

    if(isDeviceConnected.value)
    {
      Map<String, dynamic> todoEntity = t.toEntity();
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from("todos")
          .update(todoEntity)
          .select("id");

      id = response.last["id"];
      if(null == id)
      {
        throw FailureToUploadException("Failed to sync todo on update");
      }
    }
  }

  @override
  Future<void> updateBatch(List<ToDo> t) {
    // TODO: implement updateBatch
    throw UnimplementedError();
  }

  @override
  Future<void> delete(ToDo t) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<void> retry(List<ToDo> todos) async {
    late List<int?> ids;
    late int? id;
    await _isarClient.writeTxn(() async {
      ids = List<int?>.empty(growable: true);
      for(ToDo t in todos)
        {
          t.isSynced = isDevice.Connected.value;
          id = await _isarClient.todos.put(t);
          ids.add(id);
        }
    });
    if(ids.any((id) => null == id))
      {
        throw FailureToUpdateException("Failed to update todos locally");
      }
    if (isDevice.connected.value)
      {
        ids.clear();
        List<Map<String, dynamic>> todoEntities = todos.map((t) => t.toEntity()).toList();
        for(Map<String, dynamic> todoEntity in todoEntities)
          {
            final List<Map<String, dynamic>> response = await _supabaseClient
                .from("todos")
                .upsert(todoEntity)
                .select("id");
            id = response.last["id"] as int?;
            ids.add(id);
          }
        if(ids.any((id) => null == id))
          {
            throw FailureToUploadException("Failed to sync todos on update");
          }
      }
  }

  @override
  Future<void> syncRepo({bool showLoading = true}) async {
    List<int> toDeletes = await getDeleteIds();
    if(toDeletes.isEmpty)
      {
        return fetchRepo(showLoading: false);
      }
    try
        {
          await _supabaseClient
              .from("todos")
              .delete()
              .in_("id", toDeletes);

          await _isarClient.writeTxn(() async {
            await _isarClient.todos.deleteAll(toDeletes);
          });
        }
    catch (error){
      throw FailureToDeleteException("Failed to delete routines");
    }

    List<ToDo> unsyncedTodos = await getUnsynced();

    if(unsyncedTodos.isEmpty)
      {
        return fetchRepo(showLoading: false);
      }

    List<Map<String, dynamic>> syncEntities = unsyncedTodos.map((t) {
      t.isSynced = true;
      return t.toEntity();
    }).toList();

    final List<Map<String, dynamic>> responses = await _supabaseClient
      .from("todos")
      .upsert(syncEntities)
      .select("id");

    List<int?> ids =
        responses.map((response) => response["id"] as int?).toList();

    if(ids.any((id) => null == id))
      {
        throw FailureToUploadException("Failed to sync todos");
      }

    fetchRepo(showLoading: false);
  }

  @override
  Future<void> fetchRepo({bool showLoading = true}) async {
    late List<Map<String, dynamic>> todoEntities;

    await Future.delayed(const Duration(seconds: 1)).then((value) async
    {
      if(!isDeviceConnected.value)
      {
        return;
      }
      todoEntities = await _supabaseClient
          .from("todos")
          .select();

      if(todoEntities.isEmpty)
      {
        return;
      }

      List<ToDo> todos = todoEntities.map((t) => ToDo.fromEntity(entity: t)).toList();
      await _isarClient.writeTxn(() async {
        await _isarClient.clear();
        for(ToDo todo in todos)
        {
          _isarClient.todos.put(todo);
        }
      });
    });
  }

  @override
  Future<List<ToDo>> getRepoList() async{
    return _isarClient.todos.filter()
        .sortByCustomViewIndex()
        .thenById()
        .findAll();
  }

  @override
  Future<List<ToDo>> getRepoListBy({required covariant ToDoSortable sorter}) {
    // TODO: implement getRepoListBy
    throw UnimplementedError();
  }

  Future<List<int>>getDeleteIds() async => _isarClient.todos.filter().toDeleteEqualTo(true).idProperty.findAll();
  Future<List<ToDo>> getUnsynced() async => _isarClient.todos.filter().isSyncedEqualTo(false).findAll();

}