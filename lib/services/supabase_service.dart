import "dart:async";

import "package:mocktail/mocktail.dart";
import "package:supabase_flutter/supabase_flutter.dart";

// TODO: fix this once usr done. Upgrade broke stuff.
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  static SupabaseService get instance => _instance;

  late SupabaseClient _supabaseClient;
  late Stream<AuthState> _authSubscription;

  SupabaseClient get supabaseClient => _supabaseClient;

  Stream<AuthState> get authSubscription => _authSubscription;

  // late final StreamSubscription<AuthState> authSubscription;

  bool get isConnected =>
      null != _supabaseClient.auth.currentSession &&
      !_supabaseClient.auth.currentSession!.isExpired;

  bool _debug = false;
  bool get debug => _debug;

  Future<void> init(
      {required String supabaseUrl,
      required String anonKey,
      SupabaseClient? client}) async {
    if (null != client) {
      _debug = true;
      _supabaseClient = client;
      return;
    }
    await Supabase.initialize(
        url: supabaseUrl,
        anonKey: anonKey,
        storageOptions: const StorageClientOptions(
          retryAttempts: 10,
        ));
    _supabaseClient = Supabase.instance.client;

    // Initialize stream.
    _authSubscription = _supabaseClient.auth.onAuthStateChange;

    // Supabase refreshes automatically while the app is open.
    // if (_supabaseClient.auth.currentSession?.isExpired ?? false) {
    //   await _supabaseClient.auth.refreshSession();
    // }
  }

  SupabaseService._internal();
}

// NOTE: This will need some tweaking when actually testing supabase.
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
