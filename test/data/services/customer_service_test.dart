import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:urbantrack/data/models/customer/customer_input.dart';
import 'package:urbantrack/data/services/api_exception.dart';
import 'package:urbantrack/data/services/customer_service.dart';

void main() {
  test('lists customers with documented filters and pagination', () async {
    final service = CustomerService(
      Uri.parse('https://api.example.test'),
      MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/customers');
        expect(request.url.queryParameters, {
          'Status': 'Activo',
          'ExternalUserId': 'seller-id',
          'Search': 'Horizonte',
          'Page': '2',
          'PageSize': '20',
        });
        expect(request.headers['authorization'], 'Bearer access-token');
        return http.Response(
          jsonEncode({
            'customers': [
              {
                'id': 7,
                'externalId': 'customer-id',
                'name': 'Ricardo Alarcón',
                'companyName': 'Constructora Horizonte',
                'phone': '700 10001',
                'email': 'seller@example.test',
                'status': 'Activo',
                'createdAt': '2026-08-07T15:10:00Z',
                'seller': {'externalId': 'seller-id', 'name': 'Carlos Gómez'},
              },
            ],
            'page': 2,
            'pageSize': 20,
            'totalItems': 21,
            'totalPages': 2,
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final page = await service.getCustomers(
      'access-token',
      status: 'Activo',
      externalUserId: 'seller-id',
      search: ' Horizonte ',
      page: 2,
    );

    expect(page.customers.single.externalId, 'customer-id');
    expect(page.customers.single.seller?.name, 'Carlos Gómez');
    expect(page.totalItems, 21);
  });

  test('parses the customer status catalog', () async {
    final service = CustomerService(
      Uri.parse('https://api.example.test'),
      MockClient((request) async {
        expect(request.url.path, '/api/customers/statuses');
        return http.Response(
          jsonEncode([
            {'value': 1, 'label': 'Prospecto'},
            {'value': 2, 'label': 'Contactado'},
          ]),
          200,
        );
      }),
    );

    final statuses = await service.getStatuses('access-token');

    expect(statuses.map((status) => status.label), ['Prospecto', 'Contactado']);
  });

  test('keeps the API error message for a failed listing', () {
    final service = CustomerService(
      Uri.parse('https://api.example.test'),
      MockClient(
        (_) async =>
            http.Response(jsonEncode({'error': 'No autorizado.'}), 401),
      ),
    );

    expect(
      () => service.getCustomers('expired-token'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 401)
            .having((error) => error.message, 'message', 'No autorizado.'),
      ),
    );
  });

  test('parses customer detail with notes and reminders', () async {
    final service = CustomerService(
      Uri.parse('https://api.example.test'),
      MockClient((request) async {
        expect(request.url.path, '/api/customers/customer-id');
        return http.Response(
          jsonEncode({
            'id': 7,
            'externalId': 'customer-id',
            'name': 'Ricardo Alarcón',
            'companyName': 'Constructora Horizonte',
            'phone': '700 10001',
            'email': 'seller@example.test',
            'statusId': 3,
            'status': 'Activo',
            'address': 'Av. Banzer',
            'latitude': -17.75,
            'longitude': -63.18,
            'createdAt': '2026-08-07T15:00:00Z',
            'updatedAtUtc': '2026-08-18T14:30:00.1234567Z',
            'seller': {'externalId': 'seller-id', 'name': 'Carlos Gómez'},
            'notes': [
              {
                'id': 1,
                'externalId': 'note-id',
                'text': 'Solicitó una cotización.',
                'author': {'externalId': 'seller-id', 'name': 'Carlos Gómez'},
                'createdAt': '2026-08-07T16:00:00Z',
              },
            ],
            'reminders': [
              {
                'id': 2,
                'externalId': 'reminder-id',
                'text': 'Llamar por cotización',
                'reminderAt': '2026-08-08T15:00:00Z',
                'assignedTo': {
                  'externalId': 'seller-id',
                  'name': 'Carlos Gómez',
                },
                'completed': false,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final customer = await service.getCustomer('access-token', 'customer-id');

    expect(customer.notes.single.text, 'Solicitó una cotización.');
    expect(customer.reminders.single.completed, isFalse);
    expect(customer.seller?.name, 'Carlos Gómez');
    expect(customer.updatedAtUtcToken, '2026-08-18T14:30:00.1234567Z');
    expect(customer.toJson()['updatedAtUtc'], '2026-08-18T14:30:00.1234567Z');
  });

  test('sends create, update and status contracts', () async {
    final requests = <http.Request>[];
    final service = CustomerService(
      Uri.parse('https://api.example.test'),
      MockClient((request) async {
        requests.add(request);
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode({'id': 'customer-id', 'message': 'Created'}),
            201,
          );
        }
        return http.Response(jsonEncode({'message': 'Updated'}), 200);
      }),
      requestId: () => 'status-request-id',
    );
    final input = CustomerInput(
      name: 'Ricardo',
      companyName: 'Horizonte',
      phone: '70010001',
      email: '',
      sellerExternalId: null,
      address: 'Av. Banzer',
      latitude: -17.75,
      longitude: -63.18,
      expectedUpdatedAtUtc: DateTime.utc(2026, 8, 18, 14, 30),
      expectedUpdatedAtUtcToken: '2026-08-18T14:30:00.1234567Z',
    );

    final created = await service.createCustomer(
      'access-token',
      input,
      'request-id',
    );
    await service.updateCustomer('access-token', 'customer-id', input);
    await service.changeStatus('access-token', 'customer-id', 3);

    expect(created.id, 'customer-id');
    expect(requests.map((request) => request.method), ['POST', 'PUT', 'PATCH']);
    expect(jsonDecode(requests[0].body)['clientRequestId'], 'request-id');
    expect(jsonDecode(requests[0].body)['email'], isNull);
    expect(
      jsonDecode(requests[0].body).containsKey('expectedUpdatedAtUtc'),
      isFalse,
    );
    expect(
      jsonDecode(requests[1].body).containsKey('clientRequestId'),
      isFalse,
    );
    expect(
      jsonDecode(requests[1].body)['expectedUpdatedAtUtc'],
      '2026-08-18T14:30:00.1234567Z',
    );
    expect(requests[2].url.path, '/api/customers/customer-id/status');
    expect(jsonDecode(requests[2].body), {
      'statusId': 3,
      'clientRequestId': 'status-request-id',
    });
  });

  test('sends note and reminder activity contracts', () async {
    final requests = <http.Request>[];
    var generatedRequestId = 0;
    final service = CustomerService(
      Uri.parse('https://api.example.test'),
      MockClient((request) async {
        requests.add(request);
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode({'id': 'activity-id', 'message': 'Created'}),
            201,
          );
        }
        return http.Response(jsonEncode({'message': 'Completed'}), 200);
      }),
      requestId: () => 'activity-request-${++generatedRequestId}',
      now: () => DateTime.utc(2026, 8, 17, 16, 45),
    );

    await service.addNote(
      'access-token',
      'customer/id',
      'Seguimiento realizado',
      'note-request-id',
    );
    await service.addReminder(
      'access-token',
      'customer/id',
      text: 'Llamar al cliente',
      reminderAtUtc: DateTime.utc(2026, 8, 10, 14, 30),
      clientRequestId: 'reminder-request-id',
      assignedToId: 'seller-id',
    );
    await service.completeReminder(
      'access-token',
      'customer/id',
      'reminder/id',
      'complete-request-id',
    );

    expect(requests.map((request) => request.method), [
      'POST',
      'POST',
      'PATCH',
    ]);
    expect(requests[0].url.path, '/api/customers/customer%2Fid/notes');
    expect(jsonDecode(requests[0].body), {
      'text': 'Seguimiento realizado',
      'clientRequestId': 'note-request-id',
      'occurredAtUtc': '2026-08-17T16:45:00.000Z',
    });
    expect(jsonDecode(requests[1].body), {
      'text': 'Llamar al cliente',
      'reminderAtUtc': '2026-08-10T14:30:00.000Z',
      'assignedToId': 'seller-id',
      'clientRequestId': 'reminder-request-id',
    });
    expect(
      requests[2].url.path,
      '/api/customers/customer%2Fid/reminders/reminder%2Fid/complete',
    );
    expect(jsonDecode(requests[2].body), {
      'clientRequestId': 'complete-request-id',
    });
  });
}
