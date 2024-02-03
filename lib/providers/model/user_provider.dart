import 'dart:async';
import 'dart:developer';

import 'package:allocate/services/daily_reset_service.dart';
import 'package:allocate/ui/widgets/tiles.dart';
import 'package:allocate/util/enums.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../model/user/allocate_user.dart';
import '../../services/application_service.dart';
import '../../services/authentication_service.dart';
import '../../services/supabase_service.dart';
import '../../services/user_storage_service.dart';
import '../../ui/widgets/multiple_user_dialog.dart';
import '../../util/constants.dart';
import '../../util/exceptions.dart';
import '../../util/interfaces/authenticator.dart';
import '../viewmodels/user_viewmodel.dart';

class UserProvider extends ChangeNotifier {
  // This has no DI at the moment -> At some point I should probably write
  // an interface and refactor DI.
  final UserStorageService _userStorageService = UserStorageService.instance;
  late final Authenticator _authenticationService;

  // This may not be needed.
  late ValueNotifier<bool> isConnected;

  late StreamSubscription<AuthState> _connectionSubscription;

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

  late Timer updateTimer;

  UserProvider({this.viewModel, Authenticator? auth})
      : isConnected = ValueNotifier<bool>(false),
        myDayTotal = ValueNotifier<int>(0),
        _authenticationService = auth ?? AuthenticationService.instance {
    _userStorageService.addListener(handleUserStateChange);
  }

  Future<void> init() async {
    // This should never happen.
    if (_initialized) {
      return;
    }
    _initialized = true;
    _userStorageService.init();
    _authenticationService.init();
    initSubscription();
    await setUser();
    if ((viewModel?.lastOpened.day ?? Constants.today.day - Constants.today.day)
            .abs() >
        0) {
      DailyResetService.instance.dailyReset();
    }

    updateTimer = Timer.periodic(Constants.userUpdateTime, requestUpdate);
    notifyListeners();
  }

  // This is the thingy used to handle user errors.
  // Possibly use some sort of valuenotifier?
  Future<void> handleUserStateChange() async {
    switch (_userStorageService.status) {
      case UserStatus.normal:
        await setUser();
        break;
      case UserStatus.missing:
        BuildContext? context =
            ApplicationService.instance.globalNavigatorKey.currentContext;

        if (null != context) {
          Tiles.displayError(
              context: context,
              e: UserMissingException("User not found, resetting to default"));
        }
        resetUser();
        break;
      case UserStatus.multiple:
        BuildContext? context =
            ApplicationService.instance.globalNavigatorKey.currentContext;

        List<AllocateUser?> failCache = _userStorageService.failureCache;

        if (null != context) {
          AllocateUser? desiredUser = await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return MultipleUserDialog(users: failCache);
            },
          );

          if (null == desiredUser) {
            resetUser();
            failCache.clear();
            break;
          }

          failCache.remove(desiredUser);
          for (AllocateUser? user in failCache) {
            if (null != user) {
              await _userStorageService.deleteUser(user: user);
            }
          }

          viewModel?.fromModel(model: desiredUser);
          shouldUpdate = true;
          notifyListeners();
          failCache.clear();
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
          resetUser();
          failCache.clear();
          break;
        }

        failCache.remove(desiredUser);
        for (AllocateUser? user in failCache) {
          if (null != user) {
            await _userStorageService.deleteUser(user: user);
          }
        }

        viewModel?.fromModel(model: desiredUser);
        shouldUpdate = true;
        notifyListeners();
        failCache.clear();
        break;
      // This will never execute, but the testing library
      // will not work without this here.
      default:
        BuildContext? context =
            ApplicationService.instance.globalNavigatorKey.currentContext;

        if (null != context) {
          Tiles.displayError(context: context, e: UnexpectedErrorException());
        }
        // Retry the user.
        try {
          await setUser();
        } on UnexpectedErrorException catch (e, stacktrace) {
          log(e.cause, stackTrace: stacktrace);
          resetUser();
          _userStorageService.failureCache.clear();
        }
        break;
    }
  }

  void resetUser() {
    viewModel?.clear();
    shouldUpdate = true;
    notifyListeners();
  }

  void initSubscription() {
    if (SupabaseService.instance.offlineDebug) {
      return;
    }
    _connectionSubscription =
        SupabaseService.instance.authSubscription.listen((AuthState data) {
      // final AuthChangeEvent event = data.event;
      bool connection = SupabaseService.instance.isConnected;
      if (connection ^ isConnected.value) {
        isConnected.value = connection;
      }
    });
  }

  // Because this is happening in the background, I have no control
  // over catching errors. If there is a context, this will show a snackbar.
  void requestUpdate(Timer timer) async {
    if (!shouldUpdate || updating || null == viewModel) {
      return;
    }
    try {
      updateUser();
      // This will always be a wrapped exception
    } on FailureToUploadException catch (e) {
      updating = false;
      shouldUpdate = true;
      globalGUIError(e);
    } on FailureToUpdateException catch (e) {
      updating = false;
      shouldUpdate = true;
      globalGUIError(e);
    } on UnexpectedErrorException catch (e) {
      updating = false;
      shouldUpdate = false;
      globalGUIError(e);
    }
  }

  void globalGUIError(Exception? e) {
    BuildContext? context =
        ApplicationService.instance.globalNavigatorKey.currentContext;

    // no way to alert the user.
    if (null == context) {
      return;
    }

    Tiles.displayError(context: context, e: e);
  }

  Future<void> syncUser() async {
    // UserStorage catches exceptions -> will notify accordingly.
    // UserProvider has a handling routine.
    await _userStorageService.syncUser();
  }

  Future<void> updateUser() async {
    updating = true;
    try {
      await _userStorageService.updateUser(user: viewModel!.toModel());
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
      return Future.error(UnexpectedErrorException, stacktrace);
    }
    shouldUpdate = false;
    updating = false;
  }

  Future<void> signInOTP({required String email}) async {
    try {
      viewModel?.email = await _authenticationService.signInOTP(email: email);

      // These will force a rebuild + a local store.
      viewModel?.syncOnline = true;
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
      viewModel?.uuid =
          await _authenticationService.verifyOTP(email: email, token: token);
      await syncUser();
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

  // Future<void> signIn({required String email, required String password}) async {
  //   try {
  //     // On a successful auth change, UP will set isConnected.
  //     await _authenticationService.signInEmailPassword(
  //         email: email, password: password);
  //   } on LoginFailedException catch (e, stacktrace) {
  //     log(e.cause, stackTrace: stacktrace);
  //     return Future.error(e, stacktrace);
  //   } on AuthException catch (e, stacktrace) {
  //     log(e.message, stackTrace: stacktrace);
  //     return Future.error(LoginFailedException(e.message), stacktrace);
  //   } on Error catch (e, stacktrace) {
  //     log("Unknown error", stackTrace: stacktrace);
  //     return Future.error(UnexpectedErrorException(), stacktrace);
  //   }
  //   // This is just to update the vm and force a rebuild.
  //   // The user will be uploaded on the next sync sweep
  //
  //   viewModel?.email = email;
  //   viewModel?.isSynced = SupabaseService.instance.isConnected;
  // }

  Future<void> updateEmail({required String newEmail}) async {
    try {
      // THIS IS STILL THE OLD EMAIL -> Only changes on verify.
      viewModel?.email =
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

  // GOING WITH OTP.
  // Future<void> updatePassword({required String newPassword}) async {
  //   try {
  //     await _authenticationService.updatePassword(newPassword: newPassword);
  //   } on FailureToUpdateException catch (e, stacktrace) {
  //     log(e.cause, stackTrace: stacktrace);
  //     return Future.error(e, stacktrace);
  //   } on AuthException catch (e, stacktrace) {
  //     log(e.message, stackTrace: stacktrace);
  //     return Future.error(FailureToUpdateException(e.message), stacktrace);
  //   } on Error catch (e, stacktrace) {
  //     log("Unknown error", stackTrace: stacktrace);
  //     return Future.error(UnexpectedErrorException(), stacktrace);
  //   }
  // }

  // On sign-up.
  // Future<void> resendConfirmation({required String email}) async {
  //   try {
  //     await _authenticationService.resendConfirmation(email: email);
  //   } on AuthException catch (e, stacktrace) {
  //     log(e.message, stackTrace: stacktrace);
  //     return Future.error(LoginFailedException(e.message), stacktrace);
  //   } on Error catch (e, stacktrace) {
  //     log("Unknown error", stackTrace: stacktrace);
  //     return Future.error(UnexpectedErrorException(), stacktrace);
  //   }
  // }

  // Future<void> resendEmailChange({required String newEmail}) async {
  //   try {
  //     await _authenticationService.resendEmailChange(newEmail: newEmail);
  //   } on AuthException catch (e, stacktrace) {
  //     log(e.message, stackTrace: stacktrace);
  //     return Future.error(LoginFailedException(e.message), stacktrace);
  //   } on Error catch (e, stacktrace) {
  //     log("Unknown error", stackTrace: stacktrace);
  //     return Future.error(UnexpectedErrorException(), stacktrace);
  //   }
  // }

  Future<void> signOut() async {
    // if the user is offline only, there is no need to sign out.
    if (!(viewModel?.syncOnline ?? true)) {
      return;
    }
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
      }
    } on MultipleUsersException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      handleUserStateChange();
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
    notifyListeners();
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
}
