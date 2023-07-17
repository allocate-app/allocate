import '../util/interfaces/authenticator.dart';

class AuthenticationService implements Authenticator {
  @override
  Future<void> signInEmailOTP(String email) {
    // TODO: implement signInEmailOTP
    throw UnimplementedError();
  }

  @override
  Future<String> signInEmailPassword(String email, String password) {
    // TODO: implement signInEmailPassword
    throw UnimplementedError();
  }

  @override
  Future<String> signInOAuth() {
    // TODO: implement signInOAuth
    throw UnimplementedError();
  }

  @override
  Future<void> signInSMSOTP(String phone) {
    // TODO: implement signInSMSOTP
    throw UnimplementedError();
  }

  @override
  Future<String> signInWithApple() {
    // TODO: implement signInWithApple
    throw UnimplementedError();
  }

  @override
  Future<String> signUpEmailPassword(String email, String password) {
    // TODO: implement signUpEmailPassword
    throw UnimplementedError();
  }

  @override
  Future<String> verifyOTP(String token, String phone) {
    // TODO: implement verifyOTP
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() {
    // TODO: implement signOut
    throw UnimplementedError();
  }
}
