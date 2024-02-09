import 'dart:developer';

import 'package:allocate/services/daily_reset_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import "../model/user/allocate_user.dart";
import '../util/enums.dart';
import '../util/exceptions.dart';
import 'isar_service.dart';
import 'supabase_service.dart';

class UserStorageService extends ChangeNotifier {
  static final UserStorageService _instance = UserStorageService._internal();

  static UserStorageService get instance => _instance;

  late final SupabaseClient _supabaseClient;
  late final Isar _isarClient;

  late final RealtimeChannel _userStream;

  bool get isConnected => SupabaseService.instance.isConnected;

  bool _subscribed = false;
  bool _initialized = false;

  UserStatus _status = UserStatus.normal;

  UserStatus get status => _status;

  List<AllocateUser?> _failureCache = [];

  List<AllocateUser?> get failureCache => _failureCache;

  String get uuid => _supabaseClient.auth.currentUser?.id ?? "";

  String? currentUserID;

  void init() {
    if (_initialized) {
      return;
    }
    _isarClient = IsarService.instance.isarClient;
    _supabaseClient = SupabaseService.instance.supabaseClient;
    _initialized = true;

    // I haven't faked the connection channels -> doesn't make sense to.
    if (SupabaseService.instance.offlineDebug) {
      return;
    }
    // Initialize table stream -> only listen on signIn.
    // NO need to listen to insert.
    _userStream = _supabaseClient
        .channel("public:allocateUsers")
        .onPostgresChanges(
            schema: "public",
            table: "allocateUsers",
            event: PostgresChangeEvent.update,
            callback: handleUpsert)
        .onPostgresChanges(
            schema: "public",
            table: "allocateUsers",
            event: PostgresChangeEvent.delete,
            callback: handleDelete);

    SupabaseService.instance.authSubscription.listen((AuthState data) async {
      final AuthChangeEvent event = data.event;
      switch (event) {
        case AuthChangeEvent.initialSession:
          await handleUserChange();
          if (!_subscribed) {
            _userStream.subscribe();
            _subscribed = true;
          }
        case AuthChangeEvent.signedIn:
          await handleUserChange();
          // OPEN TABLE STREAM -> insert new data.
          if (!_subscribed) {
            _userStream.subscribe();
            _subscribed = true;
          }
          break;
        case AuthChangeEvent.tokenRefreshed:
          // If not listening to the stream, there hasn't been an update.
          // Sync accordingly.
          await handleUserChange();
          if (!_subscribed) {
            _userStream.subscribe();
            _subscribed = true;
          }
          break;
        case AuthChangeEvent.signedOut:
          // CLOSE TABLE STREAM.
          await _userStream.unsubscribe();
          _subscribed = false;
          break;
        default:
          break;
      }
    });

    // This is for online stuff.
    SupabaseService.instance.connectionSubscription
        .listen((ConnectivityResult result) async {
      if (result == ConnectivityResult.none) {
        return;
      }

      // This is to give enough time for the internet to check.
      await Future.delayed(const Duration(seconds: 10));
      if (!isConnected) {
        return;
      }
      await handleUserChange();
    });
  }

  void resetStatus() {
    _status = UserStatus.normal;
    _failureCache.clear();
  }

  Future<void> handleUserChange() async {
    // This should not be null, if it is connected.
    String? newID = _supabaseClient.auth.currentUser?.id;

    // RealtimeChanges will handle updated data.
    if (newID == currentUserID) {
      return syncUser();
    }

    // In the case that the previous currentUserID was null.
    // This implies a new login, or a fresh open.
    // if not online, this will just early return.
    if (null == currentUserID) {
      currentUserID = newID;
      return await syncUser();
    }

    // This implies there is a new user -> clear the DB
    // and insert the new user.
    currentUserID = newID;
    return await swapUser();
  }

  Future<void> updateUser({required AllocateUser user}) async {
    user.isSynced = isConnected;
    user.uuid = _supabaseClient.auth.currentUser!.id;
    late int? id;

    await _isarClient.writeTxn(() async {
      id = await _isarClient.allocateUsers.put(user);
    });
    if (null == id) {
      throw FailureToUpdateException("Failed to update user locally\n "
          "User: $user\n Time: ${DateTime.now()}\n"
          "Isar Open: ${_isarClient.isOpen}");
    }

    if (isConnected) {
      // Ensure the emails are correct
      user.syncOnline = true;
      user.email = _supabaseClient.auth.currentUser!.email;
      Map<String, dynamic> userEntity = user.toEntity();
      userEntity["uuid"] = _supabaseClient.auth.currentUser!.id;
      final List<Map<String, dynamic>> response = await _supabaseClient
          .from("allocateUsers")
          .upsert(userEntity)
          .select("id");

      id = response.last["id"];
      if (null == id) {
        throw FailureToUploadException("Failed to sync user on update\n"
            "User: $user\n"
            "Time: ${DateTime.now()}\n"
            "Supabase Open: $isConnected"
            "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
      }
    }
  }

  Future<void> syncUser(
      {AllocateUser? onlineUser, bool skipOnline = false}) async {
    if (!isConnected) {
      return;
    }

    AllocateUser? localUser = await getUser();

    try {
      localUser = await getUser();
      // Skipping online implies a null user.
      if (!skipOnline) {
        onlineUser = onlineUser ?? await fetchUser();
      }
      if (null == localUser && null == onlineUser) {
        _status = UserStatus.missing;
        throw UserMissingException("Local user missing from DB");
      }

      // If they're both null, there's a Missing User.
      // Thus, local user has to be non-null => upload it.
      if (null == onlineUser || onlineUser.toDelete) {
        await updateUser(user: localUser!);
      }

      // If somehow the swap failed, do it here.
      // Online user will have default params.
      if (onlineUser != localUser && !onlineUser!.toDelete) {
        await clearDB();
        await _isarClient.writeTxn(() async {
          await _isarClient.allocateUsers.put(onlineUser!);
        });
        _status = UserStatus.normal;
        notifyListeners();
        return;
      }

      // Otherwise, prioritize by lastUpdated

      // Grab the most recent user -> if it is the local one, just put back.
      // On a new sign in -> multiple users exception is thrown.
      AllocateUser toPut;
      if (localUser!.lastUpdated.isAfter(onlineUser!.lastUpdated)) {
        toPut = localUser;
      } else {
        toPut = onlineUser.copyWith(
          windowEffect: localUser.windowEffect,
          scaffoldOpacity: localUser.scaffoldOpacity,
          sidebarOpacity: localUser.sidebarOpacity,
        );

        toPut.id = localUser.id;
      }

      await updateUser(user: toPut);

      _status = UserStatus.normal;

      notifyListeners();
    } on MultipleUsersException catch (e, stacktrace) {
      _status = UserStatus.multiple;
      log(e.cause, stackTrace: stacktrace);
      // If the online user is null -> handle in UP.
      // This should never really happen.

      _failureCache = e.users;
      if (null != onlineUser) {
        _failureCache.add(onlineUser);
      }

      notifyListeners();
    }
  }

  Future<AllocateUser?> fetchUser() async {
    try {
      Map<String, dynamic>? userEntity = await _supabaseClient
          .from("allocateUsers")
          .select()
          .eq("uuid", uuid)
          .maybeSingle();

      if (null == userEntity) {
        return null;
      }

      return AllocateUser.fromEntity(entity: userEntity);
    } catch (error) {
      return null;
    }
  }

  Future<void> swapUser() async {
    // Try for an online user.
    AllocateUser? onlineUser = await fetchUser();

    if (null == onlineUser) {
      return await syncUser(skipOnline: true);
    }
    // This means there is an online user and the db is being swapped.
    // Window settings will be default.
    await clearDB();
    await _isarClient.writeTxn(() async {
      await _isarClient.allocateUsers.put(onlineUser);
    });

    _status = UserStatus.normal;
    notifyListeners();

    // This is for rescheduling notifications, etc.
    await Future.delayed(const Duration(seconds: 30)).then((_) {
      DailyResetService.instance.dailyReset();
    });
  }

  // This needs to just place the user data locally.
  Future<void> handleUpsert(PostgresChangePayload payload) async {
    AllocateUser onlineUser =
        AllocateUser.fromEntity(entity: payload.newRecord);

    AllocateUser? localUser = await getUser();

    if (null != localUser) {
      onlineUser.windowEffect = localUser.windowEffect;
      onlineUser.scaffoldOpacity = localUser.scaffoldOpacity;
      onlineUser.sidebarOpacity = localUser.sidebarOpacity;
    }
    await _isarClient.writeTxn(() async {
      await _isarClient.allocateUsers.put(onlineUser);
    });
  }

  Future<void> handleDelete(PostgresChangePayload payload) async {
    int deleteID = payload.oldRecord["id"] as int;
    await _isarClient.writeTxn(() async {
      await _isarClient.allocateUsers.delete(deleteID);
    });
  }

  Future<void> deleteUser({required AllocateUser user}) async {
    if (!user.syncOnline || null == user.uuid) {
      await _isarClient.writeTxn(() async {
        await _isarClient.allocateUsers.delete(user.id);
      });
      return;
    }

    // If there is a connection, delete the user online.
    if (isConnected) {
      // Have to delete with an edge function.
      await _supabaseClient.functions.invoke("delete_user_account");

      await _isarClient.writeTxn(() async {
        await _isarClient.allocateUsers.delete(user.id);
      });
      return;
    }

    // If there is not a connection, store for a retry.
    user.toDelete = true;
    user.syncOnline = true;
    await _isarClient.writeTxn(() async {
      await _isarClient.allocateUsers.put(user);
    });
  }

  // Grab any potentially un-deleted users and delete.
  Future<void> deleteSweep() async {
    if (!isConnected) {
      return;
    }

    List<AllocateUser> usersToDelete =
        await _isarClient.allocateUsers.where().toDeleteEqualTo(true).findAll();
    for (AllocateUser user in usersToDelete) {
      await deleteUser(user: user);
    }
  }

  Future<AllocateUser?> getUser() async {
    List<AllocateUser> users = await _isarClient.allocateUsers
        .where()
        .toDeleteEqualTo(false)
        .findAll();

    if (users.isEmpty) {
      return null;
    }

    // TODO: multi-user -> handle in secure storage.
    // Isar v3 is not encrypted.
    if (users.length > 1) {
      _failureCache = users;
      _status = UserStatus.multiple;
      throw MultipleUsersException(
          "Multiple users in database.\n"
          "Users Length: ${users.length}",
          users: users);
    }

    return users.first;
  }

  Future<void> clearDB() async {
    await _isarClient.writeTxn(() async {
      await _isarClient.allocateUsers.clear();
    });
  }

  UserStorageService._internal();
}
