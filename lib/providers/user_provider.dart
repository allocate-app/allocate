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

  int myDayTotal = 0;
  int myDayIndex = 0;

  User? curUser;

  UserProvider() {
    init();
  }

  Future<void> init() async {
    startTimer();
    getUser();
  }

  void startTimer() {
    syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (curUser?.syncOnline ?? false) {
        syncUser();
      }
    });
  }

  void refreshRoutines() {}

  // TODO: fix this. Can likely just be update.
  Future<void> createUser(
      {required String userName,
      bool syncOnline = false,
      bool? isSynced,
      int? bandwidth,
      ThemeType? theme,
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
        themeType: theme ?? ThemeType.dark,
        curMornID: curMornID,
        curAftID: curAftID,
        curEveID: curEveID,
        groupSorter: groupSorter ?? GroupSorter(),
        deadlineSorter: deadlineSorter ?? DeadlineSorter(),
        reminderSorter: reminderSorter ?? ReminderSorter(),
        routineSorter: routineSorter ?? RoutineSorter(),
        toDoSorter: toDoSorter ?? ToDoSorter(),
        lastOpened: DateTime.now());
    // This WILL require a "check close" parameter.
    // TODO: implement checkClose preference.
    // If this needs to scale, migrate data to a userprefs table and relate by uid.

    try {
      _userStorageService.createUser(user: curUser!);
    } on FailureToCreateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    notifyListeners();
  }

  Future<void> updateUser() async {
    try {
      _userStorageService.updateUser(user: curUser!);
    } on FailureToUpdateException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
    notifyListeners();
  }

  Future<void> signUp({required String email, required String password}) async {
    try {
      _authenticationService.signUpEmailPassword(
          email: email, password: password);

      //Not sure.
    } on SignUpFailedException catch (e) {
      log(e.cause);
      return Future.error(e);

      // Uh, some sort of UI thing.
    } on UserExistsException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      _authenticationService.signInEmailPassword(
          email: email, password: password);

      // For switching users.
      // -- Needs rewriting.
      _userStorageService.fetchUser();

      User? newUser = await _userStorageService.getUser();
      curUser = newUser ?? curUser;
      curUser!.syncOnline = true;
    } on LoginFailedException catch (e) {
      log(e.cause);
      return Future.error(e);

      // uh, some sort of UI thing? -> warning popup.
    } on UserSyncException catch (e) {
      // I do not know how to handle this yet - Possibly an edge function in supabase.
      log(e.cause);
      return Future.error(e);
    } on UserException catch (e) {
      log(e.cause);
      // If, for some reason, there are two users in the db,
      // opting to keep the current user to serialize and deleting the others.
      // This should have happened during the online fetch.
      _userStorageService.clearUser();
      return Future.error(e);
    }
    updateUser();
  }

  Future<void> signOut() async {
    await _authenticationService.signOut();
    curUser!.syncOnline = false;
    updateUser();
  }

  Future<void> syncUser() async {
    try {
      await _userStorageService.syncUser(user: curUser!);
    } on FailureToUploadException catch (e) {
      log(e.cause);
      return Future.error(e);
    } on UserSyncException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<void> getUser() async {
    curUser = await _userStorageService.getUser();
    notifyListeners();
  }
}
