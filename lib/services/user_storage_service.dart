import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import "../model/user/user.dart" as u;
import '../util/exceptions.dart';
import 'isar_service.dart';
import 'supabase_service.dart';

class UserStorageService {
  final SupabaseClient _supabaseClient = SupabaseService.supabaseClient;
  final Isar _isarClient = IsarService.isarClient;

  Future<void> createUser({required u.User user}) async {
    user.isSynced = (null != _supabaseClient.auth.currentSession);

    late int? id;
    await _isarClient.writeTxn(() async {
      id = await _isarClient.users.put(user);
    });
    if (null == id) {
      throw FailureToCreateException("Failed to create user locally");
    }

    user.localID = id!;

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

  Future<void> updateUser({required u.User user}) async {
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
      if (null == id) {
        throw FailureToUploadException("Failed to sync user on update");
      }
    }
  }

  Future<void> syncUser({required u.User user}) async {
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

      u.User user = u.User.fromEntity(entity: userEntities.last);

      await _isarClient.writeTxn(() async {
        await _isarClient.clear();
        await _isarClient.users.put(user);
      });
    });
  }

  Future<u.User> getUser() async => await _isarClient.users.findFirst();
  // Future<u.User> getUserByUserName({required String userName}) async =>
  //     await _isarClient.users.where().userNameEquals(userName).findAll();
}
