import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:urbantrack/data/models/auth/auth_session.dart';
import 'package:urbantrack/data/models/auth/user_profile.dart';
import 'package:urbantrack/data/repositories/remote_auth_repository.dart';
import 'package:urbantrack/data/services/auth_service.dart';
import 'package:urbantrack/data/storage/session_storage.dart';

void main() {
  test('login persists the authenticated session', () async {
    final storage = _MemorySessionStorage();
    final repository = RemoteAuthRepository(
      AuthService(
        Uri.parse('https://api.example.test'),
        MockClient((_) async => http.Response(_loginResponse(), 200)),
      ),
      storage,
      'android',
    );

    final session = await repository.login(
      email: 'seller@example.test',
      password: 'password-for-test',
    );

    expect(session.user.displayName, 'Seller Example');
    expect(storage.session, same(session));
    expect(storage.deviceIdReadCount, 1);
  });

  test(
    'restore refreshes an expired session and persists rotated tokens',
    () async {
      final storage = _MemorySessionStorage(
        session: AuthSession(
          user: const UserProfile(
            id: 1,
            fullName: 'Seller Example',
            roles: ['Seller'],
            permissions: [],
          ),
          accessToken: 'expired-access-token',
          refreshToken: 'current-refresh-token',
          expiresAtUtc: DateTime.utc(2020),
        ),
      );
      final repository = RemoteAuthRepository(
        AuthService(
          Uri.parse('https://api.example.test'),
          MockClient((request) async {
            expect(request.url.path, '/api/auth/refresh-token');
            expect(jsonDecode(request.body), {
              'refreshToken': 'current-refresh-token',
            });
            return http.Response(
              jsonEncode({
                'accessToken': 'rotated-access-token',
                'refreshToken': 'rotated-refresh-token',
                'expiresAtUtc': '2030-01-01T12:00:00Z',
              }),
              200,
            );
          }),
        ),
        storage,
        'android',
      );

      final restored = await repository.restoreSession();

      expect(restored?.accessToken, 'rotated-access-token');
      expect(restored?.refreshToken, 'rotated-refresh-token');
      expect(storage.session?.accessToken, 'rotated-access-token');
    },
  );

  test('password recovery trims user-provided email and token', () async {
    final requests = <Map<String, dynamic>>[];
    final repository = RemoteAuthRepository(
      AuthService(
        Uri.parse('https://api.example.test'),
        MockClient((request) async {
          requests.add(jsonDecode(request.body) as Map<String, dynamic>);
          return http.Response(jsonEncode({'message': 'Done.'}), 200);
        }),
      ),
      _MemorySessionStorage(),
      'android',
    );

    await repository.forgotPassword('  seller@example.test  ');
    await repository.resetPassword(
      token: '  reset-token  ',
      newPassword: 'new-password',
      confirmPassword: 'new-password',
    );

    expect(requests[0], {'email': 'seller@example.test'});
    expect(requests[1]['token'], 'reset-token');
  });
}

String _loginResponse() => jsonEncode({
  'user': {
    'id': 1,
    'fullName': 'Seller Example',
    'roles': ['Seller'],
    'permissions': <String>[],
  },
  'accessToken': 'access-token',
  'refreshToken': 'refresh-token',
  'expiresAtUtc': '2030-01-01T12:00:00Z',
});

class _MemorySessionStorage implements SessionStorage {
  _MemorySessionStorage({this.session});

  AuthSession? session;
  int deviceIdReadCount = 0;

  @override
  Future<void> clearSession() async => session = null;

  @override
  Future<String> readOrCreateDeviceId() async {
    deviceIdReadCount += 1;
    return 'installation-id';
  }

  @override
  Future<AuthSession?> readSession() async => session;

  @override
  Future<void> writeSession(AuthSession session) async {
    this.session = session;
  }
}
