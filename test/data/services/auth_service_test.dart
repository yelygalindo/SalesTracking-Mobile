import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:urbantrack/data/models/auth/forgot_password_request.dart';
import 'package:urbantrack/data/models/auth/login_request.dart';
import 'package:urbantrack/data/models/auth/reset_password_request.dart';
import 'package:urbantrack/data/services/api_exception.dart';
import 'package:urbantrack/data/services/auth_service.dart';

void main() {
  test('login sends the documented contract and parses a session', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/auth/login');
      expect(request.headers['content-type'], contains('application/json'));
      expect(jsonDecode(request.body), {
        'email': 'seller@example.test',
        'password': 'password-for-test',
        'deviceType': 'android',
        'deviceId': 'installation-id',
      });

      return http.Response(
        jsonEncode({
          'user': {
            'id': 1,
            'fullName': 'Seller Example',
            'roles': ['Seller'],
            'permissions': <String>[],
          },
          'accessToken': 'access-token',
          'refreshToken': 'refresh-token',
          'expiresAtUtc': '2030-01-01T12:00:00Z',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = AuthService(Uri.parse('https://api.example.test'), client);

    final session = await service.login(
      const LoginRequest(
        email: 'seller@example.test',
        password: 'password-for-test',
        deviceType: 'android',
        deviceId: 'installation-id',
      ),
    );

    expect(session.user.displayName, 'Seller Example');
    expect(session.accessToken, 'access-token');
  });

  test('login maps an empty unauthorized response safely', () async {
    final service = AuthService(
      Uri.parse('https://api.example.test'),
      MockClient((_) async => http.Response('', 401)),
    );

    expect(
      () => service.login(
        const LoginRequest(
          email: 'seller@example.test',
          password: 'wrong-password',
          deviceType: 'android',
          deviceId: 'installation-id',
        ),
      ),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 401)
            .having(
              (error) => error.message,
              'message',
              'Correo o contraseña incorrectos.',
            ),
      ),
    );
  });

  test('forgot password sends the documented email payload', () async {
    final service = AuthService(
      Uri.parse('https://api.example.test'),
      MockClient((request) async {
        expect(request.url.path, '/api/auth/forgot-password');
        expect(jsonDecode(request.body), {'email': 'seller@example.test'});
        return http.Response(
          jsonEncode({'message': 'Instructions sent.'}),
          200,
        );
      }),
    );

    final message = await service.forgotPassword(
      const ForgotPasswordRequest(email: 'seller@example.test'),
    );

    expect(
      message,
      'Si el correo está registrado, recibirás instrucciones para restablecer tu contraseña.',
    );
  });

  test('reset password sends token and matching passwords', () async {
    final service = AuthService(
      Uri.parse('https://api.example.test'),
      MockClient((request) async {
        expect(request.url.path, '/api/auth/reset-password');
        expect(jsonDecode(request.body), {
          'token': 'reset-token',
          'newPassword': 'new-password',
          'confirmPassword': 'new-password',
        });
        return http.Response(jsonEncode({'message': 'Password updated.'}), 200);
      }),
    );

    final message = await service.resetPassword(
      const ResetPasswordRequest(
        token: 'reset-token',
        newPassword: 'new-password',
        confirmPassword: 'new-password',
      ),
    );

    expect(message, 'Password updated.');
  });
}
