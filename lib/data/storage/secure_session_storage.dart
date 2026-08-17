import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/auth/auth_session.dart';
import 'session_storage.dart';

class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage(this._storage);

  static const _sessionKey = 'urbantrack.auth.session.v1';
  static const _deviceIdKey = 'urbantrack.installation.id.v1';
  static const _lastUserIdKey = 'urbantrack.auth.last-user-id.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthSession?> readSession() async {
    final serialized = await _storage.read(key: _sessionKey);
    if (serialized == null || serialized.isEmpty) return null;

    try {
      final decoded = jsonDecode(serialized);
      if (decoded is! Map<String, dynamic>) return null;
      return AuthSession.fromJson(decoded);
    } on FormatException {
      await clearSession();
      return null;
    }
  }

  @override
  Future<void> writeSession(AuthSession session) {
    return _storage.write(
      key: _sessionKey,
      value: jsonEncode(session.toJson()),
    );
  }

  @override
  Future<void> clearSession() => _storage.delete(key: _sessionKey);

  @override
  Future<String?> readLastAuthenticatedUserId() async {
    final value = await _storage.read(key: _lastUserIdKey);
    return value?.trim().isNotEmpty == true ? value!.trim() : null;
  }

  @override
  Future<void> writeLastAuthenticatedUserId(String userId) {
    return _storage.write(key: _lastUserIdKey, value: userId);
  }

  @override
  Future<String> readOrCreateDeviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final created = const Uuid().v4();
    await _storage.write(key: _deviceIdKey, value: created);
    return created;
  }
}
