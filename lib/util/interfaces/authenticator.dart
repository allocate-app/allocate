import 'dart:core';

abstract interface class Authenticator {
  Future<void> signInEmailPassword(
      {required String email, required String password});

  Future<String?> signUpEmailPassword(
      {required String email, required String password});

  Future<void> signOut();

  Future<String?> updateEmail({required String newEmail});

  Future<void> updatePassword({required String newPassword});

  Future<void> resendConfirmation({required String email});

  Future<void> resendEmailChange({required String newEmail});

  Future<void> passwordRecovery({required String email});
}
