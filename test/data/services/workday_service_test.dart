import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:urbantrack/data/models/workday/close_workday_request.dart';
import 'package:urbantrack/data/models/workday/start_workday_request.dart';
import 'package:urbantrack/data/services/api_exception.dart';
import 'package:urbantrack/data/services/workday_service.dart';

void main() {
  test('gets the current workday with the authenticated contract', () async {
    final service = WorkdayService(
      Uri.parse('https://api.example.test'),
      MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/workdays/current');
        expect(request.headers['authorization'], 'Bearer access-token');
        return http.Response(
          jsonEncode({'hasOpenWorkday': true, 'workday': _workdayJson()}),
          200,
        );
      }),
    );

    final response = await service.getCurrent('access-token');

    expect(response.hasOpenWorkday, isTrue);
    expect(response.workday?.externalId, 'workday-1');
    expect(response.workday?.startLatitude, -12.0464);
  });

  test('starts a workday with mobile time, GPS and request id', () async {
    final service = WorkdayService(
      Uri.parse('https://api.example.test'),
      MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/workdays');
        expect(request.headers['authorization'], 'Bearer access-token');
        expect(jsonDecode(request.body), {
          'startedAtUtc': '2026-08-07T15:10:00.000Z',
          'latitude': -12.0464,
          'longitude': -77.0428,
          'note': 'Inicio en campo',
          'clientRequestId': 'request-start',
        });
        return http.Response(
          jsonEncode({'workday': _workdayJson(), 'message': 'Created'}),
          201,
        );
      }),
    );

    final workday = await service.start(
      'access-token',
      StartWorkdayRequest(
        startedAtUtc: DateTime.utc(2026, 8, 7, 15, 10),
        latitude: -12.0464,
        longitude: -77.0428,
        note: 'Inicio en campo',
        clientRequestId: 'request-start',
      ),
    );

    expect(workday.isOpen, isTrue);
  });

  test('closes the identified workday and exposes API conflict details', () {
    final service = WorkdayService(
      Uri.parse('https://api.example.test'),
      MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/workdays/workday-1/close');
        expect(jsonDecode(request.body), {
          'endedAtUtc': '2026-08-07T22:00:00.000Z',
          'latitude': -12.05,
          'longitude': -77.04,
          'clientRequestId': 'request-close',
        });
        return http.Response(
          jsonEncode({'error': 'La jornada ya fue cerrada.'}),
          409,
        );
      }),
    );

    expect(
      () => service.close(
        'access-token',
        'workday-1',
        CloseWorkdayRequest(
          endedAtUtc: DateTime.utc(2026, 8, 7, 22),
          latitude: -12.05,
          longitude: -77.04,
          clientRequestId: 'request-close',
        ),
      ),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 409)
            .having(
              (error) => error.message,
              'message',
              'La jornada ya fue cerrada.',
            ),
      ),
    );
  });
}

Map<String, dynamic> _workdayJson() => {
  'id': 'workday-1',
  'status': 'open',
  'startedAtUtc': '2026-08-07T15:10:00Z',
  'startedReceivedAtUtc': '2026-08-07T15:10:02Z',
  'startLatitude': -12.0464,
  'startLongitude': -77.0428,
  'note': 'Inicio en campo',
  'endedAtUtc': null,
  'endedReceivedAtUtc': null,
  'endLatitude': null,
  'endLongitude': null,
};
