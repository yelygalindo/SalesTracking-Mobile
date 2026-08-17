import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:urbantrack/data/models/auth/auth_session.dart';
import 'package:urbantrack/data/models/auth/user_profile.dart';
import 'package:urbantrack/data/repositories/auth_repository.dart';
import 'package:urbantrack/data/repositories/remote_customer_repository.dart';
import 'package:urbantrack/data/services/customer_service.dart';

void main() {
  test(
    'assigns a seller reminder to the authenticated user by default',
    () async {
      Map<String, dynamic>? payload;
      final service = CustomerService(
        Uri.parse('https://api.example.test'),
        MockClient((request) async {
          payload = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({'id': 'reminder-id', 'message': 'Created'}),
            201,
          );
        }),
        requestId: () => 'request-id',
      );
      final repository = RemoteCustomerRepository(
        service,
        _SessionAuthRepository(),
      );

      await repository.addReminder(
        'customer-id',
        text: 'Llamar al cliente',
        reminderAtUtc: DateTime.utc(2026, 8, 18, 14),
      );

      expect(payload?['assignedToId'], 'seller-id');
    },
  );

  test('preserves an explicitly selected reminder assignee', () async {
    Map<String, dynamic>? payload;
    final service = CustomerService(
      Uri.parse('https://api.example.test'),
      MockClient((request) async {
        payload = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({'id': 'reminder-id', 'message': 'Created'}),
          201,
        );
      }),
      requestId: () => 'request-id',
    );
    final repository = RemoteCustomerRepository(
      service,
      _SessionAuthRepository(),
    );

    await repository.addReminder(
      'customer-id',
      text: 'Visitar al cliente',
      reminderAtUtc: DateTime.utc(2026, 8, 18, 15),
      assignedToId: 'another-seller-id',
    );

    expect(payload?['assignedToId'], 'another-seller-id');
  });
}

class _SessionAuthRepository implements AuthRepository {
  @override
  Future<AuthSession?> restoreSession() async => AuthSession(
    user: const UserProfile(
      id: 7,
      externalId: 'seller-id',
      roles: ['Seller'],
      permissions: [],
    ),
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    expiresAtUtc: DateTime.now().toUtc().add(const Duration(hours: 1)),
  );

  @override
  Future<String> forgotPassword(String email) => throw UnimplementedError();

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> logout(AuthSession session) => throw UnimplementedError();

  @override
  Future<String> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) => throw UnimplementedError();
}
