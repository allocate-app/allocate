import 'package:allocate/services/supabase_service.dart';
import 'package:allocate/util/exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../util/interfaces/authenticator.dart';

class AuthenticationService implements Authenticator {
  final SupabaseClient _supabaseClient =
      SupabaseService.instance.supabaseClient;

  @override
  Future<void> signUpEmailPassword(
      {required String email, required String password}) async {
    final response = await _supabaseClient.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: (kIsWeb) ? null : "io.supabase.flutter://login/",
    );
    final userID = response.user?.id;
    if (null == userID) {
      throw SignUpFailedException("Connection or API error");
    }
    // If a user already exists, whether verified or not, reroute to login.
    if (null != response.user?.identities &&
        response.user!.identities!.isNotEmpty) {
      throw UserExistsException("Email already verified");
    }
  }

  @override
  Future<void> signInEmailPassword(
      {required String email, required String password}) async {
    final response = await _supabaseClient.auth
        .signInWithPassword(email: email, password: password);
    final userID = response.user?.id;
    if (null == userID) {
      throw LoginFailedException("Connection error or invalid credentials");
    }
  }

  @override
  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }

  // TODO: Finish these -- They will need screens.
  Future<void> updateEmail({required String newEmail}) async {
    await _supabaseClient.auth.resend(
        type: OtpType.emailChange,
        email: newEmail,
        emailRedirectTo:
            (kIsWeb) ? null : "io.supabase.flutter://update-email/");
  }

  // TODO: finish these -- They will need screens
  Future<void> passwordRecovery({required String email}) async {
    await _supabaseClient.auth.resetPasswordForEmail(email,
        redirectTo: (kIsWeb) ? null : "io.supabase.flutter://password/");
  }
}
