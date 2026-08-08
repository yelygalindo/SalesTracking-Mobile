import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:urbantrack/data/models/project/project_input.dart';
import 'package:urbantrack/data/services/project_service.dart';

void main() {
  test('lists the project status catalog', () async {
    final service = ProjectService(
      Uri.parse('https://api.example.test'),
      MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/projects/statuses');
        expect(request.headers['Authorization'], 'Bearer access-token');
        return http.Response(
          jsonEncode([
            {'value': 1, 'label': 'Borrador'},
            {'value': 2, 'label': 'Activo'},
            {'value': 3, 'label': 'En pausa'},
            {'value': 4, 'label': 'Completado'},
            {'value': 5, 'label': 'Cancelado'},
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final statuses = await service.getStatuses('access-token');

    expect(statuses, hasLength(5));
    expect(statuses.first.value, 1);
    expect(statuses.first.label, 'Borrador');
    expect(statuses.last.label, 'Cancelado');
  });

  test('lists projects using the documented pagination envelope', () async {
    final service = ProjectService(
      Uri.parse('https://api.example.test'),
      MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/projects');
        expect(request.url.queryParameters, {
          'status': 'Activo',
          'customerId': 'customer-id',
          'sellerId': 'seller-id',
          'page': '2',
          'pageSize': '20',
        });
        return http.Response(
          jsonEncode({
            'items': [_projectJson],
            'pagination': {
              'page': 2,
              'pageSize': 20,
              'totalItems': 21,
              'totalPages': 2,
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final page = await service.getProjects(
      'access-token',
      status: 'Activo',
      customerId: 'customer-id',
      sellerId: 'seller-id',
      page: 2,
    );

    expect(page.projects.single.name, 'Obra Norte');
    expect(page.projects.single.progressPercentage, 45);
    expect(page.totalItems, 21);
  });

  test('sends create, update and status project contracts', () async {
    final requests = <http.Request>[];
    final service = ProjectService(
      Uri.parse('https://api.example.test'),
      MockClient((request) async {
        requests.add(request);
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode(_projectJson),
            201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(jsonEncode({'message': 'Updated'}), 200);
      }),
    );
    final input = ProjectInput(
      name: 'Obra Norte',
      description: 'Edificio residencial',
      customerExternalId: 'customer-id',
      sellerExternalId: null,
      estimatedAmount: 185000,
      startDateUtc: DateTime.utc(2026, 8, 1),
      expectedCloseDateUtc: DateTime.utc(2026, 10, 30),
      progressPercentage: 45,
      actualCloseDateUtc: null,
      address: 'Av. Banzer',
      latitude: -17.75,
      longitude: -63.18,
    );

    final created = await service.createProject(
      'access-token',
      input,
      'request-id',
    );
    await service.updateProject('access-token', 'project-id', input);
    await service.changeStatus('access-token', 'project-id', 3);

    expect(created.externalId, 'project-id');
    expect(requests.map((request) => request.method), ['POST', 'PUT', 'PATCH']);
    expect(jsonDecode(requests[0].body)['clientRequestId'], 'request-id');
    expect(
      jsonDecode(requests[1].body).containsKey('clientRequestId'),
      isFalse,
    );
    expect(jsonDecode(requests[2].body), {'statusId': 3});
  });
}

final _projectJson = {
  'id': 4,
  'externalId': 'project-id',
  'name': 'Obra Norte',
  'description': 'Edificio residencial',
  'customerExternalId': 'customer-id',
  'customerName': 'Constructora Horizonte',
  'sellerExternalId': 'seller-id',
  'sellerName': 'Carlos Gómez',
  'status': 'Activo',
  'estimatedAmount': 185000.0,
  'startDateUtc': '2026-08-01T00:00:00Z',
  'expectedCloseDateUtc': '2026-10-30T00:00:00Z',
  'progressPercentage': 45.0,
  'actualCloseDateUtc': null,
  'address': 'Av. Banzer',
  'latitude': -17.75,
  'longitude': -63.18,
  'createdAtUtc': '2026-08-01T12:00:00Z',
};
