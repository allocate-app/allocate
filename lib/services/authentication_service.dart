import 'package:supabase_flutter/supabase_flutter.dart';

import '../util/exceptions.dart';
import '../util/interfaces/authenticator.dart';
import 'supabase_service.dart';

// TODO: finish this once deep-linking set up -> I believe this needs some sort pragma.
class AuthenticationService implements Authenticator {
  static final AuthenticationService _instance =
      AuthenticationService._internal();

  static AuthenticationService get instance => _instance;
  final SupabaseClient _supabaseClient =
      SupabaseService.instance.supabaseClient;

  @override
  Future<String?> signUpEmailPassword(
      {required String email, required String password}) async {
    final response = await _supabaseClient.auth.signUp(
      email: email,
      password: password,
    );

    final String? userID = response.user?.id;
    if (null == userID) {
      throw SignUpFailedException("Connection or API error");
    }
    if (null != response.user?.identities &&
        response.user!.identities!.isNotEmpty) {
      throw UserExistsException("Email already verified");
    }
    return userID;
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

  @override
  Future<String?> updateEmail({required String newEmail}) async {
    final UserResponse res = await _supabaseClient.auth.updateUser(
      UserAttributes(
        email: newEmail,
      ),
    );

    if (null == res.user || null == res.user?.email) {
      throw FailureToUpdateException("Unable to update email\n"
          "Supabase Open: ${null != _supabaseClient.auth.currentSession}"
          "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
    }
    return res.user?.newEmail;
  }

  // I'm not sure whether or not this should...check?
  @override
  Future<void> resendConfirmation({required String email}) async {
    final ResendResponse result = await _supabaseClient.auth.resend(
      type: OtpType.email,
      email: email,
    );
  }

  @override
  Future<void> resendEmailChange({required String newEmail}) async {
    final ResendResponse result = await _supabaseClient.auth.resend(
      type: OtpType.emailChange,
      email: newEmail,
    );
  }

  @override
  Future<void> passwordRecovery({required String email}) async {
    await _supabaseClient.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    final UserResponse res = await _supabaseClient.auth.updateUser(
      UserAttributes(password: newPassword),
    );

    if (null == res.user) {
      throw FailureToUpdateException("Unable to update password\n"
          "Supabase Open: ${null != _supabaseClient.auth.currentSession}"
          "Session expired: ${_supabaseClient.auth.currentSession?.isExpired}");
    }

    await _supabaseClient.auth.reauthenticate();
  }

  AuthenticationService._internal();
}
