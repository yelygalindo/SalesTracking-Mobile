import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:urbantrack/data/models/auth/auth_session.dart';
import 'package:urbantrack/data/models/auth/user_profile.dart';
import 'package:urbantrack/data/repositories/auth_repository.dart';
import 'package:urbantrack/data/repositories/remote_history_repository.dart';
import 'package:urbantrack/data/services/history_service.dart';

void main() {
  test(
    'falls back to visit history when seller timeline is forbidden',
    () async {
      final requestedPaths = <String>[];
      final service = HistoryService(
        Uri.parse('https://api.example.test'),
        MockClient((request) async {
          requestedPaths.add(request.url.path);
          if (request.url.path == '/api/sellers/seller-id/timeline') {
            return http.Response('', 403);
          }
          expect(request.url.path, '/api/visits');
          expect(request.url.queryParameters['SellerExternalId'], 'seller-id');
          return http.Response(
            jsonEncode([_visitJson]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final repository = RemoteHistoryRepository(
        service,
        _SessionAuthRepository(),
      );

      final page = await repository.getMyTimeline(
        from: DateTime.utc(2026, 8, 3),
        to: DateTime.utc(2026, 8, 4),
      );

      expect(requestedPaths, [
        '/api/sellers/seller-id/timeline',
        '/api/visits',
      ]);
      expect(page.items, hasLength(2));
      expect(page.items.first.title, 'Visita finalizada · Obra Norte');
      expect(page.items.last.title, 'Visita iniciada · Obra Norte');
      expect(page.items.first.description, contains('Cotización entregada'));
    },
  );
}

class _SessionAuthRepository implements AuthRepository {
  @override
  Future<AuthSession?> restoreSession() async => AuthSession(
    user: const UserProfile(
      id: 1,
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

final _visitJson = {
  'externalId': 'visit-id',
  'projectExternalId': 'project-id',
  'projectName': 'Obra Norte',
  'customerExternalId': 'customer-id',
  'customerName': 'Constructora Horizonte',
  'visitedAtUtc': '2026-08-03T14:10:00Z',
  'latitude': -17.7833,
  'longitude': -63.1821,
  'notes': 'Revisar avance',
  'checkOutAtUtc': '2026-08-03T15:05:00Z',
  'checkOutLatitude': -17.7834,
  'checkOutLongitude': -63.1822,
  'checkOutNote': 'Revisar precios el viernes',
  'result': 'Cotización entregada',
  'sellerExternalId': 'seller-id',
  'sellerName': 'Carlos Gómez',
};
