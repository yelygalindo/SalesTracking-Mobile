import '../models/auth/auth_session.dart';

abstract interface class AuthRepository {
  Future<AuthSession?> restoreSession();

  Future<AuthSession> login({required String email, required String password});

  Future<String> forgotPassword(String email);

  Future<String> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  });

  Future<void> logout(AuthSession session);
}
