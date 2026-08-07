import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/auth/auth_session.dart';

void main() {
  test('auth session parses and serializes the API contract', () {
    final json = <String, dynamic>{
      'user': <String, dynamic>{
        'id': 42,
        'externalId': 'user-external-id',
        'username': 'seller',
        'fullName': 'Seller Example',
        'company': <String, dynamic>{
          'id': 7,
          'externalId': 'company-external-id',
          'name': 'Example Company',
        },
        'email': 'seller@example.test',
        'roles': <String>['Seller'],
        'permissions': <String>['customers.read'],
      },
      'accessToken': 'access-token',
      'refreshToken': 'refresh-token',
      'expiresAtUtc': '2030-01-01T12:00:00Z',
    };

    final session = AuthSession.fromJson(json);

    expect(session.user.id, 42);
    expect(session.user.company?.name, 'Example Company');
    expect(session.user.roles, ['Seller']);
    expect(session.expiresAtUtc, DateTime.utc(2030, 1, 1, 12));
    final serialized = session.toJson();
    expect(serialized['user'], json['user']);
    expect(serialized['accessToken'], 'access-token');
    expect(serialized['refreshToken'], 'refresh-token');
    expect(serialized['expiresAtUtc'], '2030-01-01T12:00:00.000Z');
  });

  test('auth session rejects missing tokens', () {
    expect(
      () => AuthSession.fromJson({
        'user': <String, dynamic>{'id': 1},
        'accessToken': '',
        'refreshToken': 'refresh-token',
        'expiresAtUtc': '2030-01-01T12:00:00Z',
      }),
      throwsFormatException,
    );
  });
}
