import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../model/user/user.dart';
import '../services/authentication_service.dart';
import '../services/user_storage_service.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/sorting/deadline_sorter.dart';
import '../util/sorting/group_sorter.dart';
import '../util/sorting/reminder_sorter.dart';
import '../util/sorting/routine_sorter.dart';
import '../util/sorting/todo_sorter.dart';

class UserProvider extends ChangeNotifier {
  late Timer syncTimer;
  final _userStorageService = UserStorageService();
  final _authenticationService = AuthenticationService();

  late User? curUser;

  bool retry = false;

  UserProvider() {
    startTimer();
    init();
  }

  Future<void> init() async {
    getUser();
    notifyListeners();
  }

  void startTimer() {
    syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (retry) {
        retry = false;
        updateUser();
      }
      if (curUser?.syncOnline ?? false) {
        syncUser();
      }
    });
  }

  Future<void> createUser(
      {required String userName,
      bool syncOnline = false,
      bool? isSynced,
      int? bandwidth,
      Theme? theme,
      int? curMornID,
      int? curAftID,
      int? curEveID,
      GroupSorter? groupSorter,
      DeadlineSorter? deadlineSorter,
      ReminderSorter? reminderSorter,
      RoutineSorter? routineSorter,
      ToDoSorter? toDoSorter}) async {
    curUser = User(
        userName: userName,
        syncOnline: syncOnline,
        isSynced: isSynced ?? false,
        curTheme: theme ?? Theme.dark,
        curMornID: curMornID,
        curAftID: curAftID,
        curEveID: curEveID,
        groupSorter: groupSorter,
        deadlineSorter: deadlineSorter,
        reminderSorter: reminderSorter,
        routineSorter: routineSorter,
        toDoSorter: toDoSorter);

    try {
      _userStorageService.createUser(user: curUser!);
    } on FailureToCreateException catch (e) {
      log(e.cause);
      retry = true;
    } on FailureToUploadException catch (e) {
      log(e.cause);
      retry = true;
    }
    notifyListeners();
  }

  Future<void> updateUser(
      {String? userName,
      bool? syncOnline,
      bool? isSynced,
      int? bandwidth,
      Theme? theme,
      int? curMornID,
      int? curAftID,
      int? curEveID,
      GroupSorter? groupSorter,
      DeadlineSorter? deadlineSorter,
      ReminderSorter? reminderSorter,
      RoutineSorter? routineSorter,
      ToDoSorter? toDoSorter}) async {
    User user = curUser!.copyWith(
        userName: userName,
        syncOnline: syncOnline,
        isSynced: isSynced,
        bandwidth: bandwidth,
        curTheme: theme,
        curMornID: curMornID,
        curAftID: curAftID,
        curEveID: curEveID,
        groupSorter: groupSorter,
        deadlineSorter: deadlineSorter,
        reminderSorter: reminderSorter,
        routineSorter: routineSorter,
        toDoSorter: toDoSorter);

    user.localID = curUser!.localID;
    curUser = user;

    try {
      _userStorageService.updateUser(user: curUser!);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      retry = true;
    } on FailureToUploadException catch (e) {
      log(e.cause);
      retry = true;
    }
    notifyListeners();
  }

  Future<void> signUp({required String email, required String password}) async {
    try {
      _authenticationService.signUpEmailPassword(
          email: email, password: password);

      // Pop Up with button to move to log-in page?

      //Not sure.
    } on SignUpFailedException catch (e) {
      log(e.cause);
      // Uh, some sort of UI thing.
    } on UserExistsException catch (e) {
      log(e.cause);
      // Route to log-in page, warn user that login exists.
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      _authenticationService.signInEmailPassword(
          email: email, password: password);

      // For switching users.
      _userStorageService.fetchUser();

      User? newUser = await _userStorageService.getUser();
      curUser = newUser ?? curUser;
    } on LoginFailedException catch (e) {
      log(e.cause);
      return;
      // uh, some sort of UI thing? -> warning popup.
    } on UserSyncException catch (e) {
      // I do not know how to handle this yet - Possibly an edge function in supabase.
      log(e.cause);
      log("This is a fatal error");
      retry = true;
      return;
    } on UserException catch (e) {
      log(e.cause);
      _userStorageService.clearUser();
    }
    updateUser(syncOnline: true);
  }

  Future<void> signOut() async {
    await _authenticationService.signOut();
    updateUser(syncOnline: false);
  }

  Future<void> syncUser() async {
    try {
      await _userStorageService.syncUser(user: curUser!);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      retry = true;
    } on UserSyncException catch (e) {
      log(e.cause);
      log("This is a fatal error");
      // Some sort of UI whoopsie.
      // I do not know how to handle this yet.
      retry = true;
    }
  }

  Future<void> getUser() async => curUser = await _userStorageService.getUser();
}
