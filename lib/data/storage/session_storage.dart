import '../models/auth/auth_session.dart';

abstract interface class SessionStorage {
  Future<AuthSession?> readSession();

  Future<void> writeSession(AuthSession session);

  Future<void> clearSession();

  Future<String> readOrCreateDeviceId();
}
