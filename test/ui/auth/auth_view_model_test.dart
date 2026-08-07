import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/auth/auth_session.dart';
import 'package:urbantrack/data/models/auth/user_profile.dart';
import 'package:urbantrack/data/repositories/auth_repository.dart';
import 'package:urbantrack/data/services/api_exception.dart';
import 'package:urbantrack/ui/auth/auth_view_model.dart';

void main() {
  test('restores an existing session', () async {
    final repository = _FakeAuthRepository(session: _session());
    final viewModel = AuthViewModel(repository);

    await viewModel.restoreSession();

    expect(viewModel.status, AuthStatus.authenticated);
    expect(viewModel.session?.user.displayName, 'Seller Example');
  });

  test('exposes a safe API error after failed login', () async {
    final repository = _FakeAuthRepository(
      loginError: const ApiException(
        statusCode: 401,
        message: 'Correo o contraseña incorrectos.',
      ),
    );
    final viewModel = AuthViewModel(repository);

    final success = await viewModel.login(
      email: 'seller@example.test',
      password: 'wrong-password',
    );

    expect(success, isFalse);
    expect(viewModel.status, AuthStatus.unauthenticated);
    expect(viewModel.errorMessage, 'Correo o contraseña incorrectos.');
  });
}

AuthSession _session() => AuthSession(
  user: const UserProfile(
    id: 1,
    fullName: 'Seller Example',
    roles: ['Seller'],
    permissions: [],
  ),
  accessToken: 'access-token',
  refreshToken: 'refresh-token',
  expiresAtUtc: DateTime.utc(2030),
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.session, this.loginError});

  final AuthSession? session;
  final Object? loginError;

  @override
  Future<AuthSession?> restoreSession() async => session;

  @override
  Future<AuthSession> login({required String email, required String password}) {
    final error = loginError;
    if (error != null) return Future.error(error);
    return Future.value(session ?? _session());
  }

  @override
  Future<void> logout(AuthSession session) async {}
}
