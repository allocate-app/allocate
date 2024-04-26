import 'dart:async';
import 'dart:developer';

import 'package:allocate/services/daily_reset_service.dart';
import 'package:allocate/ui/widgets/tiles.dart';
import 'package:allocate/util/enums.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../model/user/allocate_user.dart';
import '../../services/application_service.dart';
import '../../services/authentication_service.dart';
import '../../services/supabase_service.dart';
import '../../services/user_storage_service.dart';
import '../../ui/blurred_dialog.dart';
import '../../ui/widgets/multiple_user_dialog.dart';
import '../../util/constants.dart';
import '../../util/exceptions.dart';
import '../../util/interfaces/authenticator.dart';
import '../viewmodels/user_viewmodel.dart';

// TODO: clean this class up.
class UserProvider extends ChangeNotifier {
  // This has no DI at the moment -> At some point I should probably write
  // an interface and refactor DI.
  final UserStorageService _userStorageService = UserStorageService.instance;
  late final Authenticator _authenticationService;

  // This may not be needed.
  late ValueNotifier<bool> isConnected;

  late StreamSubscription<AuthState> _supabaseSubscription;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  late ValueNotifier<int> myDayTotal;

  bool shouldUpdate = false;
  bool updating = false;
  bool _initialized = false;

  bool get initialized => _initialized;

  // FUTURE TODO: multiple user switching.
  int _userCount = 1;

  int get userCount => _userCount;

  set userCount(int newCount) {
    if (newCount > Constants.maxUserCount) {
      return;
    }
    _userCount = newCount;
    notifyListeners();
  }

  UserViewModel? viewModel;

  // late Timer updateTimer;

  UserProvider({this.viewModel, Authenticator? auth})
      : isConnected = ValueNotifier<bool>(false),
        myDayTotal = ValueNotifier<int>(0),
        _authenticationService = auth ?? AuthenticationService.instance {
    _userStorageService.addListener(handleUserStateChange);
  }

  Future<void> init({bool firstLaunch = true}) async {
    // This should never happen.
    if (_initialized) {
      return;
    }
    _initialized = true;
    // TODO: -> DB needs to be queried/synced BEFORE setting the user.
    await _userStorageService.init();
    _authenticationService.init();
    initSubscription();

    if (firstLaunch) {
      await setUser();
    }

    notifyListeners();
  }

  Future<void> handleUserStateChange() async {
    switch (_userStorageService.status) {
      case UserStatus.normal:
        await setUser();
        break;
      case UserStatus.missing:
        BuildContext? context =
            ApplicationService.instance.globalNavigatorKey.currentContext;

        if (null != context && context.mounted) {
          await Tiles.displayError(
              e: UserMissingException("User not found, resetting to default"));
        }

        await setUser();
        _userStorageService.resetStatus();
        break;
      case UserStatus.multiple:
        BuildContext? context =
            ApplicationService.instance.globalNavigatorKey.currentContext;

        List<AllocateUser?> failCache = _userStorageService.failureCache;

        if (null != context) {
          AllocateUser? desiredUser = await blurredNonDismissible(
              context: context, dialog: MultipleUserDialog(users: failCache));
          // showDialog(
          //   useRootNavigator: false,
          //   context: context,
          //   barrierDismissible: false,
          //   builder: (BuildContext context) {
          //     return MultipleUserDialog(users: failCache);
          //   },
          // );

          if (null == desiredUser) {
            await resetUser();
            break;
          }

          await _userStorageService.clearDB();
          viewModel?.fromModel(model: desiredUser);
          shouldUpdate = true;
          await updateUser();
          notifyListeners();
          _userStorageService.resetStatus();
          break;
        }

        // If for some reason the context is null, go with the most recently
        // updated user.
        failCache.sort((u1, u2) {
          if (null == u1) {
            return -1;
          }
          if (null == u2) {
            return 1;
          }

          return u1.lastUpdated.compareTo(u2.lastUpdated);
        });

        AllocateUser? desiredUser = failCache.firstOrNull;
        if (null == desiredUser) {
          await resetUser();
          break;
        }

        await _userStorageService.clearDB();
        viewModel?.fromModel(model: desiredUser);
        shouldUpdate = true;
        await updateUser();
        notifyListeners();
        _userStorageService.resetStatus();
        break;

      default:
        BuildContext? context =
            ApplicationService.instance.globalNavigatorKey.currentContext;

        if (null != context && context.mounted) {
          await Tiles.displayError(e: UnexpectedErrorException());
        }
        // Retry the user.
        try {
          await setUser();
        } on UnexpectedErrorException catch (e, stacktrace) {
          log(e.cause, stackTrace: stacktrace);
          await resetUser();
        }
        break;
    }
  }

  Future<void> resetUser() async {
    _userStorageService.clearDB();
    await setUser();
    _userStorageService.resetStatus();
  }

  void initSubscription() {
    if (SupabaseService.instance.offlineDebug) {
      return;
    }

    _supabaseSubscription =
        SupabaseService.instance.authSubscription.listen((AuthState data) {
      if (AuthChangeEvent.signedOut == data.event) {
        isConnected.value = false;
        return;
      }

      isConnected.value = SupabaseService.instance.isConnected;
    });

    // TODO: There is likely a bug here -> on re-connection, gui not updating.
    // This probably should just listen to the isConnected value.
    // I think what's happening, is that supabase fails to reconnect
    // before this runs, or, this runs, then supabase works to re-establish conn?.
    // I am unsure.
    // It may be best to refactor this to just listen to the supabase connection.
    // YEAH, uh, YIKES.
    _connectivitySubscription = SupabaseService.instance.connectionSubscription
        .listen((ConnectivityResult result) async {
      // This is a bit inefficient to grab twice, but this is for syncing + GUI.
      isConnected.value = await InternetConnectionChecker().hasConnection &&
          SupabaseService.instance.isConnected;
    });
  }

  // void requestUpdate(Timer timer) async {
  //   if (!shouldUpdate || updating || null == viewModel) {
  //     return;
  //   }
  //   try {
  //     await updateUser();
  //     // This will always be a wrapped exception
  //   } on FailureToUploadException catch (e) {
  //     updating = false;
  //     shouldUpdate = true;
  //     globalGUIError(e);
  //   } on FailureToUpdateException catch (e) {
  //     updating = false;
  //     shouldUpdate = true;
  //     globalGUIError(e);
  //   } on UnexpectedErrorException catch (e) {
  //     updating = false;
  //     shouldUpdate = false;
  //     globalGUIError(e);
  //   }
  // }

  Future<void> globalGUIError(Exception? e) async {
    BuildContext? context =
        ApplicationService.instance.globalNavigatorKey.currentContext;

    // no way to alert the user.
    if (null == context || !context.mounted) {
      return;
    }

    await Tiles.displayError(e: e);
  }

  // TODO: refactor -> sync user only.
  Future<void> syncUser() async {
    try {
      if (shouldUpdate) {
        await _userStorageService.updateUser(user: viewModel!.toModel());
      } else {
        await _userStorageService.syncUser();
        await setUser();
      }
    } on Error catch (e, stacktrace) {
      log(e.toString(), stackTrace: stacktrace);
    }
  }

  Future<void> updateUser() async {
    try {
      await _userStorageService.updateUser(user: viewModel!.toModel());
      viewModel!.pushUpdate = false;
      notifyListeners();
    } on FailureToUpdateException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      shouldUpdate = true;
      return Future.error(e, stacktrace);
    } on FailureToUploadException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      shouldUpdate = true;
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> signInOTP({required String email}) async {
    try {
      await _authenticationService.signInOTP(email: email);
    } on LoginFailedException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      return Future.error(e, stacktrace);
    } on AuthException catch (e, stacktrace) {
      log(e.message, stackTrace: stacktrace);
      return Future.error(SignUpFailedException(e.message), stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> verifyOTP({required String email, required String token}) async {
    try {
      await _authenticationService.verifySignInOTP(email: email, token: token);
      // // This might actually be automatic.
      // shouldUpdate = true;
      // await updateUser();
    } on LoginFailedException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      return Future.error(e, stacktrace);
    } on AuthException catch (e, stacktrace) {
      log(e.message, stackTrace: stacktrace);
      return Future.error(SignUpFailedException(e.message), stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  // This just sends an OTP.
  Future<void> updateEmail({required String newEmail}) async {
    try {
      await _authenticationService.updateEmail(newEmail: newEmail);
    } on FailureToUpdateException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      return Future.error(e, stacktrace);
    } on AuthException catch (e, stacktrace) {
      log(e.message, stackTrace: stacktrace);
      return Future.error(FailureToUpdateException(e.message), stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  // TODO: test the otp.
  Future<void> verifiyEmailChange(
      {required String newEmail, required String token}) async {
    try {
      // THIS IS THE NEW EMAIL - Test this at some point.
      viewModel?.email = await _authenticationService.verifyEmailChangeOTP(
          email: newEmail, token: token);

      shouldUpdate = true;
      await updateUser();
    } on EmailChangeException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      return Future.error(e, stacktrace);
    } on AuthException catch (e, stacktrace) {
      log(e.message, stackTrace: stacktrace);
      return Future.error(FailureToUpdateException(e.message), stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> signOut() async {
    try {
      await _authenticationService.signOut();
    } on AuthException catch (e, stacktrace) {
      log(e.message, stackTrace: stacktrace);
      return Future.error(SignOutFailedException(e.message), stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  // Get the user, initialize the viewmodel.
  Future<void> setUser() async {
    try {
      AllocateUser? user = await _userStorageService.getUser();
      if (null != user) {
        viewModel?.fromModel(model: user);
      } else {
        viewModel?.clear();
        shouldUpdate = true;
        await updateUser();
      }

      notifyListeners();
    } on MultipleUsersException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      await handleUserStateChange();
      notifyListeners();
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> deleteUser() async {
    AllocateUser? user = viewModel?.toModel();
    if (null != user) {
      try {
        await _userStorageService.deleteUser(user: user);
        await signOut();
      } on FailureToDeleteException catch (e, stacktrace) {
        log(e.cause, stackTrace: stacktrace);
        return Future.error(e, stacktrace);
      } on AuthException catch (e, stacktrace) {
        log(e.message, stackTrace: stacktrace);
        return Future.error(SignOutFailedException(e.message), stacktrace);
      } on Error catch (e, stacktrace) {
        log("Unknown error", stackTrace: stacktrace);
        return Future.error(UnexpectedErrorException(), stacktrace);
      }
    }

    viewModel?.clear();
    notifyListeners();
  }

  Future<void> dayReset() async {
    await _userStorageService.deleteSweep();
  }

  void checkDay() async {
    if ((viewModel?.lastOpened.copyWith(
                hour: 0,
                minute: 0,
                second: 0,
                millisecond: 0,
                microsecond: 0) ??
            Constants.today)
        .isAfter(Constants.today)) {
      DailyResetService.instance.dailyReset();
    }

    viewModel?.lastOpened = DateTime.now();
  }

  void updateConnectionStatus() {
    isConnected.value = SupabaseService.instance.isConnected;
  }
}
