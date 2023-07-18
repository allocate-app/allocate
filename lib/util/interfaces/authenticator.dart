import 'dart:core';

abstract interface class Authenticator {
  Future<void> signInEmailPassword(
      {required String email, required String password});
  Future<void> signUpEmailPassword(
      {required String email, required String password});

  // These require configuration - Consider adding later.
  // Also: No Linux-Supabase redirect yet. Add later.
  // Future<void> signInSMSOTP(String phone);
  // Future<void> verifyOTP(String token, String phone);
  // Future<void> signInWithApple();
  //Future<void> signInOAuth();

  Future<void> signOut();
}
