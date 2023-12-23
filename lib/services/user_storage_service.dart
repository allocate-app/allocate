import 'dart:developer';

import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import "../model/user/user.dart";
import '../util/exceptions.dart';
import 'isar_service.dart';
import 'supabase_service.dart';

class UserStorageService {
  final SupabaseClient _supabaseClient =
      SupabaseService.instance.supabaseClient;
  final Isar _isarClient = IsarService.instance.isarClient;

  Future<void> createUser({required User user}) async {
    user.isSynced = (null != _supabaseClient.auth.currentSession);

    late int? id;
    await _isarClient.writeTxn(() async {
      id = await _isarClient.users.put(user);
    });
    if (null == id) {
      throw FailureToCreateException("Failed to create user locally \n"
          "User: ${user.toString()}");
    }

    if (null != _supabaseClient.auth.currentSession) {
      Map<String, dynamic> userEntity = user.toEntity();
      final List<Map<String, dynamic>> response =
          await _supabaseClient.from("users").insert(userEntity).select("id");
      id = response.last["id"];

      if (null == id) {
        throw FailureToUploadException("Failed to sync user on create");
      }
    }
  }

  Future<void> updateUser({required User user}) async {
    user.isSynced = (null != _supabaseClient.auth.currentSession);
    late int? id;
    await _isarClient.writeTxn(() async {
      id = await _isarClient.users.put(user);
    });
    if (null == id) {
      throw FailureToUpdateException("Failed to update user locally");
    }
    if (null != _supabaseClient.auth.currentSession) {
      Map<String, dynamic> userEntity = user.toEntity();
      final List<Map<String, dynamic>> response =
          await _supabaseClient.from("users").upsert(userEntity).select("id");

      id = response.last["id"];
      if (null == id) {
        throw FailureToUploadException("Failed to sync user on update");
      }
    }
  }

  Future<void> syncUser({required User user}) async {
    if (user.isSynced) {
      return fetchUser();
    }

    late int? id;
    user.isSynced = true;
    Map<String, dynamic> userEntity = user.toEntity();

    final List<Map<String, dynamic>> response =
        await _supabaseClient.from("users").upsert(userEntity).select("id");
    id = response.last["id"];
    if (null == id) {
      throw FailureToUploadException("Failed to sync user");
    }
    fetchUser();
  }

  Future<void> fetchUser() async {
    late List<Map<String, dynamic>> userEntities;

    await Future.delayed(const Duration(seconds: 1)).then((value) async {
      if (null == _supabaseClient.auth.currentSession) {
        return;
      }
      userEntities = await _supabaseClient.from("users").select();
      if (userEntities.length > 1 || userEntities.isEmpty) {
        throw UserSyncException(
            "ERROR - Number of users found: ${userEntities.length}");
      }

      User user = User.fromEntity(entity: userEntities.last);

      await _isarClient.writeTxn(() async {
        await _isarClient.users.clear();
        await _isarClient.users.put(user);
      });
    });
  }

  Future<void> clearUser() async => await _isarClient.writeTxn(() async {
        await _isarClient.users.clear();
      });

  Future<User?> getUser() async {
    List<User> users = await _isarClient.users.where().findAll();
    if (users.length > 1) {
      throw UserException("Multiple users in db");
    }
    try {
      User user = users.first;
      return user;
    } on StateError catch (e) {
      log(e.message);
      return null;
    }
  }
}
