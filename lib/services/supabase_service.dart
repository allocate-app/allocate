import "dart:async";

import "package:connectivity_plus/connectivity_plus.dart";
import "package:internet_connection_checker/internet_connection_checker.dart";
import "package:mocktail/mocktail.dart";
import "package:supabase_flutter/supabase_flutter.dart";

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  static SupabaseService get instance => _instance;

  late SupabaseClient _supabaseClient;
  late Stream<AuthState> _authSubscription;
  late Stream<ConnectivityResult> _connectionSubscription;

  SupabaseClient get supabaseClient => _supabaseClient;

  Stream<AuthState> get authSubscription => _authSubscription;

  Stream<ConnectivityResult> get connectionSubscription =>
      _connectionSubscription;

  late bool _initialized = false;

  bool hasInternet = false;

  bool get isConnected =>
      hasInternet &&
      null != _supabaseClient.auth.currentSession &&
      !_supabaseClient.auth.currentSession!.isExpired;

  bool _offline = false;

  bool get offlineOnly => _offline;

  Future<void> init(
      {required String supabaseUrl,
      required String anonKey,
      SupabaseClient? client}) async {
    if (_initialized) {
      return;
    }

    if (null != client) {
      _offline = true;
      _supabaseClient = client;
      _initialized = true;
      return;
    }

    // SET THE INTERNET CONNECTION STATUS.
    hasInternet = await InternetConnectionChecker().hasConnection;

    // Test retry attempts.
    await Supabase.initialize(
        url: supabaseUrl,
        anonKey: anonKey,
        storageOptions: const StorageClientOptions(
          retryAttempts: 0,
        ));
    _supabaseClient = Supabase.instance.client;

    // Initialize stream.
    _authSubscription = _supabaseClient.auth.onAuthStateChange;
    _connectionSubscription = Connectivity().onConnectivityChanged;
    _connectionSubscription.listen(updateConnectionStatus);

    // Supabase refreshes automatically while the app is open.
    // if (_supabaseClient.auth.currentSession?.isExpired ?? false) {
    //   await _supabaseClient.auth.refreshSession();
    // }

    _initialized = true;
  }

  Future<void> updateConnectionStatus(ConnectivityResult result) async {
    hasInternet = await InternetConnectionChecker().hasConnection;
  }

  SupabaseService._internal();
}

class FakeSupabase extends Fake implements SupabaseClient {
  @override
  get auth => FakeGoTrue();
}

class FakeGoTrue extends Fake implements GoTrueClient {
  final _user = User(
    id: "id",
    appMetadata: {},
    userMetadata: {},
    aud: "aud",
    createdAt: DateTime.now().toIso8601String(),
  );

  @override
  Future<AuthResponse> signInWithPassword(
      {String? email,
      String? phone,
      required String password,
      String? captchaToken}) async {
    return AuthResponse(session: null, user: _user);
  }

  @override
  Session? get currentSession => null;
}
