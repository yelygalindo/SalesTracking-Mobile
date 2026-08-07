import '../models/auth/auth_session.dart';
import '../models/auth/forgot_password_request.dart';
import '../models/auth/login_request.dart';
import '../models/auth/reset_password_request.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../storage/session_storage.dart';
import 'auth_repository.dart';

class RemoteAuthRepository implements AuthRepository {
  const RemoteAuthRepository(
    this._authService,
    this._sessionStorage,
    this._deviceType,
  );

  final AuthService _authService;
  final SessionStorage _sessionStorage;
  final String _deviceType;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final deviceId = await _sessionStorage.readOrCreateDeviceId();
    final session = await _authService.login(
      LoginRequest(
        email: email.trim(),
        password: password,
        deviceType: _deviceType,
        deviceId: deviceId,
      ),
    );
    await _sessionStorage.writeSession(session);
    return session;
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final stored = await _sessionStorage.readSession();
    if (stored == null || !stored.isExpired) return stored;

    try {
      final refreshed = await _authService.refresh(stored.refreshToken);
      final session = stored.withTokens(
        accessToken: refreshed.accessToken,
        refreshToken: refreshed.refreshToken,
        expiresAtUtc: refreshed.expiresAtUtc,
      );
      await _sessionStorage.writeSession(session);
      return session;
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _sessionStorage.clearSession();
        return null;
      }

      // Keep the last authenticated identity available while offline. API calls
      // will refresh the token once connectivity returns.
      return stored;
    }
  }

  @override
  Future<String> forgotPassword(String email) {
    return _authService.forgotPassword(
      ForgotPasswordRequest(email: email.trim()),
    );
  }

  @override
  Future<String> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _authService.resetPassword(
      ResetPasswordRequest(
        token: token.trim(),
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      ),
    );
  }

  @override
  Future<void> logout(AuthSession session) async {
    try {
      final deviceId = await _sessionStorage.readOrCreateDeviceId();
      await _authService.logout(session: session, deviceId: deviceId);
    } finally {
      await _sessionStorage.clearSession();
    }
  }
}
