import 'dart:async';
import 'dart:developer';

import 'package:allocate/providers/application/daily_reset_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../model/user/allocate_user.dart';
import '../../services/authentication_service.dart';
import '../../services/supabase_service.dart';
import '../../services/user_storage_service.dart';
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

  // FUTURE TODO: user switching with secure-storage.
  // TODO: call init on splash screen to handle multiple-users in db.
  UserProvider({this.viewModel, Authenticator? auth})
      : isConnected = ValueNotifier<bool>(false),
        myDayTotal = ValueNotifier<int>(0),
        _authenticationService = auth ?? AuthenticationService.instance {
    init().whenComplete(notifyListeners);
  }

  Future<void> init() async {
    initSubscription();
    await setUser();
    if ((viewModel?.lastOpened.day ?? Constants.today.day - Constants.today.day)
            .abs() >
        0) {
      DailyResetProvider.instance.dailyReset();
    }

    updateTimer = Timer.periodic(Constants.userUpdateTime, requestUpdate);
  }

  void initSubscription() {
    if (SupabaseService.instance.debug) {
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

  void requestUpdate(Timer timer) {
    if (!shouldUpdate || updating || null == viewModel) {
      return;
    }
    updateUser();
  }

  Future<void> updateUser() async {
    updating = true;
    try {
      await _userStorageService.updateUser(user: viewModel!.toModel());
    } on FailureToUpdateException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      shouldUpdate = true;
      return Future.error(e);
    } on FailureToUploadException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      shouldUpdate = true;
      return Future.error(e);
    }
    shouldUpdate = false;
    updating = false;
  }

  Future<void> signUp({required String email, required String password}) async {
    try {
      // This also throws UserExistsException -> catch accordingly
      viewModel?.uuid = await _authenticationService.signUpEmailPassword(
          email: email, password: password);

      viewModel?.syncOnline = true;
    } on SignUpFailedException catch (e) {
      log(e.cause);
      return Future.error(e);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _authenticationService.signUpEmailPassword(
          email: email, password: password);
    } on LoginFailedException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
    }
    viewModel?.isSynced = SupabaseService.instance.isConnected;
  }

  Future<void> updateEmail({required String newEmail}) async {
    try {
      viewModel?.email =
          await _authenticationService.updateEmail(newEmail: newEmail);
    } on FailureToUpdateException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      return Future.error(e, stacktrace);
    }
  }

  Future<void> updatePassword({required String newPassword}) async {
    try {
      await _authenticationService.updatePassword(newPassword: newPassword);
    } on FailureToUpdateException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      return Future.error(e, stacktrace);
    }
  }

  // On sign-up.
  Future<void> resendConfirmation({required String email}) async {
    await _authenticationService.resendConfirmation(email: email);
  }

  Future<void> resendEmailChange({required String newEmail}) async {
    await _authenticationService.resendEmailChange(newEmail: newEmail);
  }

  Future<void> signOut() async {
    await _authenticationService.signOut();
  }

  // Get the user, initialize the viewmodel.
  Future<void> setUser() async {
    try {
      AllocateUser? user = await _userStorageService.getUser();
      if (null != user) {
        viewModel?.fromModel(model: user);
      }
      // This has a reference to the list of multiple users.
      // TODO: Handle in the gui -> SplashScrn.
    } on MultipleUsersException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      return Future.error(e, stacktrace);
    }
    notifyListeners();
  }

  Future<void> deleteUser() async {
    AllocateUser? user = viewModel?.toModel();
    if (null != user) {
      try {
        await _userStorageService.deleteUser(user: user);
      } on FailureToDeleteException catch (e, stacktrace) {
        log(e.cause, stackTrace: stacktrace);
      }
    }

    await signOut();
    viewModel?.clear();
    notifyListeners();
  }

  Future<void> dayReset() async {
    await _userStorageService.deleteSweep();
  }
}
