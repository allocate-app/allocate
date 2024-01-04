import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../model/user/user.dart';
import '../services/authentication_service.dart';
import '../services/user_storage_service.dart';
import '../util/constants.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/sorting/deadline_sorter.dart';
import '../util/sorting/group_sorter.dart';
import '../util/sorting/reminder_sorter.dart';
import '../util/sorting/routine_sorter.dart';
import '../util/sorting/todo_sorter.dart';

// TODO: re-implement this -> Migrate params to an AppProvider.
class UserProvider extends ChangeNotifier {
  late Timer syncTimer;
  final _userStorageService = UserStorageService();
  final _authenticationService = AuthenticationService();

  int myDayTotal = 0;
  int _myDayIndex = 0;

  Size _size = const Size(0, 0);

  bool _largeScreen = false;
  bool _hugeScreen = false;
  bool _smallScreen = false;

  bool _win11 = false;
  bool isTablet = false;

  // not sure if this is needed yet
  bool isMobile = false;

  bool _drawerOpened = true;
  double _navDrawerWidth = Constants.navigationDrawerMaxWidth;

  PackageInfo _packageInfo = PackageInfo(
    appName: "",
    packageName: "",
    version: "",
    buildNumber: "",
    buildSignature: "",
    installerStore: "",
  );

  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  late WindowsDeviceInfo _windowsDeviceInfo;

  int get myDayIndex => _myDayIndex;

  set myDayIndex(int index) {
    _myDayIndex = index;
    notifyListeners();
  }

  Size get size => _size;

  set size(Size newSize) {
    _size = newSize;
    _smallScreen = width <= Constants.smallScreen;
    _largeScreen = width >= Constants.largeScreen;
    _hugeScreen = width >= Constants.hugeScreen;
    if (_myDayIndex == Constants.tabs.length - 1 && wideView) {
      _myDayIndex = 0;
    }
  }

  double get height => size.height;

  double get width => size.width;

  bool get drawerOpened => _drawerOpened;

  set drawerOpened(bool opened) {
    _drawerOpened = opened;
    if (_myDayIndex == Constants.tabs.length - 1 && wideView) {
      _myDayIndex = 0;
    }
    notifyListeners();
  }

  double get navDrawerWidth => _navDrawerWidth;

  set navDrawerWidth(double navDrawerWidth) {
    bool breakpoint =
        ((_navDrawerWidth < Constants.navigationDrawerMinThreshold) ^
            (navDrawerWidth < Constants.navigationDrawerMinThreshold));

    _navDrawerWidth = navDrawerWidth;

    // If there is no breakpoint passed, no need to force a rebuild.
    if (!breakpoint) {
      return;
    }

    if (_myDayIndex == Constants.tabs.length - 1 && wideView) {
      _myDayIndex = 0;
    }

    notifyListeners();
  }

  bool get smallScreen => _smallScreen;

  bool get largeScreen => _largeScreen;

  bool get hugeScreen => _hugeScreen;

  bool get wideView =>
      _hugeScreen ||
      (_largeScreen &&
          (!_drawerOpened ||
              // This is because of dragging
              _navDrawerWidth < Constants.navigationDrawerMinThreshold));

  bool get win11 => _win11;

  PackageInfo get packageInfo => _packageInfo;

  set win11(bool isWin11) {
    _win11 = isWin11;
    notifyListeners();
  }

  User? curUser;
  List<User> users = [];

  UserProvider() {
    init();
  }

  // Init.
  // Get user, (last updated)
  // Swap user, *maybe store JWT?* see if possible
  // Sign in -> should query supabase.
  // Sign out.
  // Update user.
  // None of this sync nonsense.

  Future<void> init() async {
    startTimer();
    getUser();
    _initPackageInfo();
    if (Platform.isWindows) {
      _initDeviceInfo();
    }
  }

  Future<void> _initPackageInfo() async {
    _packageInfo = await PackageInfo.fromPlatform();
    notifyListeners();
  }

  // Right now, all that's needed is windows.
  // io handles most other cases.
  // Notifies.
  Future<void> _initDeviceInfo() async {
    _windowsDeviceInfo = await _deviceInfoPlugin.windowsInfo;
    win11 = (_windowsDeviceInfo.buildNumber >= 22000);
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
        username: userName,
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
        lastOpened: DateTime.now(),
        lastUpdated: DateTime.now(),
        primarySeed: Constants.defaultPrimaryColorSeed);
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
