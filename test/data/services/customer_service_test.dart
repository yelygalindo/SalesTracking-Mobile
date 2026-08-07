import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
}
