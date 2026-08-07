import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:urbantrack/data/models/common/location_sample.dart';
import 'package:urbantrack/data/models/visit/visit_target_type.dart';
import 'package:urbantrack/data/services/visit_service.dart';

void main() {
  test('returns no active visit for a 204 response', () async {
    final service = VisitService(
      Uri.parse('https://api.example.test'),
      MockClient((request) async {
        expect(request.url.path, '/api/visits/current');
        return http.Response('', 204);
      }),
    );

    expect(await service.getCurrent('access-token'), isNull);
  });

  test('parses the current visit', () async {
    final service = VisitService(
      Uri.parse('https://api.example.test'),
      MockClient(
        (_) async => http.Response(
          jsonEncode({
            'type': 'project',
            'visitExternalId': 'visit-id',
            'targetExternalId': 'project-id',
            'targetName': 'Obra Norte',
            'checkInAtUtc': '2026-08-07T16:00:00Z',
            'latitude': -17.75,
            'longitude': -63.18,
            'note': 'Revisar avance',
          }),
          200,
        ),
      ),
    );

    final visit = await service.getCurrent('access-token');

    expect(visit?.type, VisitTargetType.project);
    expect(visit?.targetName, 'Obra Norte');
  });

  test('sends check-in and check-out time, GPS and request ids', () async {
    final requests = <http.Request>[];
    final service = VisitService(
      Uri.parse('https://api.example.test'),
      MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({'id': 'visit-id', 'message': 'Saved'}),
          request.method == 'POST' ? 201 : 200,
        );
      }),
    );

    await service.checkIn(
      'access-token',
      targetType: VisitTargetType.customer,
      targetExternalId: 'customer-id',
      checkInAtUtc: DateTime.utc(2026, 8, 7, 16),
      location: _location,
      clientRequestId: 'check-in-request',
      note: 'Presentar propuesta',
    );
    await service.checkOut(
      'access-token',
      targetType: VisitTargetType.project,
      targetExternalId: 'project-id',
      visitExternalId: 'visit-id',
      checkOutAtUtc: DateTime.utc(2026, 8, 7, 17),
      location: _location,
      clientRequestId: 'check-out-request',
      note: 'Avance validado',
      result: 'Gestión realizada',
    );

    expect(requests[0].url.path, '/api/customers/customer-id/visits');
    expect(
      requests[1].url.path,
      '/api/projects/project-id/visits/visit-id/checkout',
    );
    expect(jsonDecode(requests[0].body), {
      'checkInAtUtc': '2026-08-07T16:00:00.000Z',
      'latitude': -17.75,
      'longitude': -63.18,
      'note': 'Presentar propuesta',
      'clientRequestId': 'check-in-request',
    });
    expect(jsonDecode(requests[1].body)['result'], 'Gestión realizada');
    expect(
      jsonDecode(requests[1].body)['clientRequestId'],
      'check-out-request',
    );
  });
}

const _location = LocationSample(
  latitude: -17.75,
  longitude: -63.18,
  accuracyMeters: 6,
);
