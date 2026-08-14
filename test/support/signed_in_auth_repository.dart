import 'package:urbantrack/data/models/auth/auth_session.dart';
import 'package:urbantrack/data/models/auth/user_profile.dart';
import 'package:urbantrack/data/repositories/auth_repository.dart';

class SignedInAuthRepository implements AuthRepository {
  int logoutCalls = 0;

  final AuthSession session = AuthSession(
    user: const UserProfile(
      id: 1,
      externalId: 'seller-test-id',
      username: 'seller.test',
      fullName: 'Vendedor de prueba',
      email: 'seller@example.test',
      roles: ['Seller'],
      permissions: [],
    ),
    accessToken: 'test-access-token',
    refreshToken: 'test-refresh-token',
    expiresAtUtc: DateTime.utc(2099),
  );

  @override
  Future<String> forgotPassword(String email) async => 'Instructions sent.';

  @override
  Future<AuthSession> login({required String email, required String password}) {
    return Future.value(session);
  }

  @override
  Future<void> logout(AuthSession session) async {
    logoutCalls += 1;
  }

  @override
  Future<String> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async => 'Password updated.';

  @override
  Future<AuthSession?> restoreSession() async => session;
}
