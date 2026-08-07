import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/auth/auth_session.dart';
import 'package:urbantrack/data/repositories/auth_repository.dart';
import 'package:urbantrack/data/services/api_exception.dart';
import 'package:urbantrack/ui/auth/password_recovery_view_model.dart';

void main() {
  test('reports success after requesting recovery instructions', () async {
    final viewModel = PasswordRecoveryViewModel(_RecoveryRepository());

    final success = await viewModel.requestReset('seller@example.test');

    expect(success, isTrue);
    expect(viewModel.status, PasswordRecoveryStatus.success);
    expect(viewModel.message, 'Instructions sent.');
  });

  test('reports an API failure while resetting a password', () async {
    final viewModel = PasswordRecoveryViewModel(
      _RecoveryRepository(
        resetError: const ApiException(
          statusCode: 400,
          message: 'El token no es válido.',
        ),
      ),
    );

    final success = await viewModel.resetPassword(
      token: 'invalid-token',
      newPassword: 'new-password',
      confirmPassword: 'new-password',
    );

    expect(success, isFalse);
    expect(viewModel.status, PasswordRecoveryStatus.failure);
    expect(viewModel.message, 'El token no es válido.');
  });
}

class _RecoveryRepository implements AuthRepository {
  _RecoveryRepository({this.resetError});

  final Object? resetError;

  @override
  Future<String> forgotPassword(String email) async => 'Instructions sent.';

  @override
  Future<AuthSession> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout(AuthSession session) async {}

  @override
  Future<String> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) {
    final error = resetError;
    if (error != null) return Future.error(error);
    return Future.value('Password updated.');
  }

  @override
  Future<AuthSession?> restoreSession() async => null;
}
