import 'dart:core';

abstract interface class Authenticator {
  // Future<void> signInEmailPassword(
  //     {required String email, required String password});

  void init();

  Future<String> signInOTP({required String email});

  Future<void> signOut();

  Future<String?> updateEmail({required String newEmail});

  Future<String> verifySignInOTP(
      {required String email, required String token});
  Future<String> verifyEmailChangeOTP(
      {required String email, required String token});

// Future<void> updatePassword({required String newPassword});
//
// Future<void> resendConfirmation({required String email});

// Future<void> resendEmailChange({required String newEmail});

// Future<void> passwordRecovery({required String email});
}
