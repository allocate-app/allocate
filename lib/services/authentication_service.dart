import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../util/constants.dart';
import '../util/exceptions.dart';
import '../util/interfaces/authenticator.dart';
import 'supabase_service.dart';

class AuthenticationService implements Authenticator {
  static final AuthenticationService _instance =
      AuthenticationService._internal();

  static AuthenticationService get instance => _instance;

  late final SupabaseClient _supabaseClient;

  @override
  void init() {
    _supabaseClient = SupabaseService.instance.supabaseClient;
  }

  // Creation happens on OTP link generation.
  @override
  Future<String> signInOTP({required String email}) async {
    try {
      await _supabaseClient.auth.signInWithOtp(
          email: email,
          shouldCreateUser: true,
          emailRedirectTo: Constants.loginDeeplink);
    } on AuthException catch (e, stacktrace) {
      log(e.message, stackTrace: stacktrace);
      return Future.error(LoginFailedException(e.message), stacktrace);
    }

    return email;
  }

  @override
  Future<String> verifyOTP(
      {required String email, required String token}) async {
    final response = await _supabaseClient.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.magiclink,
    );
    if (null == response.user || null == response.user?.id) {
      throw LoginFailedException(
          "Invalid email/token\nemail: $email\ntoken: $token");
    }

    return response.user!.id;
  }

  @override
  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }

  @override
  Future<String?> updateEmail({required String newEmail}) async {
    final UserResponse res = await _supabaseClient.auth.updateUser(
        UserAttributes(
          email: newEmail,
        ),
        emailRedirectTo: Constants.emailDeeplink);

    if (null == res.user || null == res.user?.email) {
      throw FailureToUpdateException("Unable to update email\n"
          "Supabase Open: ${null != _supabaseClient.auth.currentSession}"
          "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
    }
    return res.user?.email;
  }

  AuthenticationService._internal();
}
