import 'dart:core';

abstract interface class Authenticator {
  Future<String> signInEmailPassword(String email, String password);
  Future<String> signUpEmailPassword(String email, String password);

  // These require configuration
  Future<void> signInEmailOTP(String email);
  Future<void> signInSMSOTP(String phone);
  Future<String> verifyOTP(String token, String phone);

  Future<String> signInWithApple();
  Future<String> signInOAuth();

  Future<void> signOut();
}
