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

  test(
    'lists notes and timeline and sends the project note contract',
    () async {
      final requests = <http.Request>[];
      final service = ProjectService(
        Uri.parse('https://api.example.test'),
        MockClient((request) async {
          requests.add(request);
          if (request.method == 'POST') {
            return http.Response(
              jsonEncode({'id': 'note-id', 'message': 'Created'}),
              201,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          if (request.url.path.endsWith('/timeline')) {
            return http.Response(
              jsonEncode({
                'items': [_timelineJson],
                'pagination': {
                  'page': 2,
                  'pageSize': 25,
                  'totalItems': 26,
                  'totalPages': 2,
                },
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          return http.Response(
            jsonEncode([_noteJson]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final notes = await service.getNotes('access-token', 'project/id');
      final timeline = await service.getTimeline(
        'access-token',
        'project/id',
        page: 2,
        pageSize: 25,
      );
      final created = await service.addNote(
        'access-token',
        'project/id',
        content: '  Avance confirmado  ',
        clientRequestId: 'request-id',
        occurredAtUtc: DateTime.utc(2026, 8, 11, 10, 35),
      );

      expect(notes.single.content, 'Avance confirmado');
      expect(notes.single.createdBy?.name, 'Carlos Gómez');
      expect(timeline.items.single.title, 'Visita finalizada');
      expect(timeline.totalPages, 2);
      expect(created.id, 'note-id');
      expect(requests[0].url.path, '/api/projects/project%2Fid/notes');
      expect(requests[1].url.queryParameters, {'Page': '2', 'PageSize': '25'});
      expect(jsonDecode(requests[2].body), {
        'content': 'Avance confirmado',
        'clientRequestId': 'request-id',
        'occurredAtUtc': '2026-08-11T10:35:00.000Z',
      });
    },
  );

  test('lists, creates and completes project reminders', () async {
    final requests = <http.Request>[];
    var requestNumber = 0;
    final service = ProjectService(
      Uri.parse('https://api.example.test'),
      MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode([_reminderJson]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode({'id': 'reminder-id', 'message': 'Created'}),
            201,
          );
        }
        return http.Response(jsonEncode({'message': 'Completed'}), 200);
      }),
      requestId: () => 'reminder-request-${++requestNumber}',
    );

    final reminders = await service.getReminders(
      'access-token',
      'project/id',
      completed: false,
    );
    await service.addReminder(
      'access-token',
      'project/id',
      text: 'Confirmar materiales',
      reminderAtUtc: DateTime.utc(2026, 8, 18, 14),
      assignedToId: 'seller-id',
    );
    await service.completeReminder('access-token', 'project/id', 'reminder/id');

    expect(reminders.single.text, 'Confirmar materiales');
    expect(reminders.single.assignedTo?.externalId, 'seller-id');
    expect(requests[0].url.path, '/api/projects/project%2Fid/reminders');
    expect(requests[0].url.queryParameters, {'completed': 'false'});
    expect(jsonDecode(requests[1].body), {
      'text': 'Confirmar materiales',
      'reminderAtUtc': '2026-08-18T14:00:00.000Z',
      'assignedToId': 'seller-id',
      'clientRequestId': 'reminder-request-1',
    });
    expect(
      requests[2].url.path,
      '/api/projects/project%2Fid/reminders/reminder%2Fid/complete',
    );
    expect(jsonDecode(requests[2].body), {
      'clientRequestId': 'reminder-request-2',
    });
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

final _noteJson = {
  'id': 1,
  'externalId': 'note-id',
  'content': 'Avance confirmado',
  'createdBy': {'externalId': 'seller-id', 'name': 'Carlos Gómez'},
  'createdAtUtc': '2026-08-11T10:36:00Z',
  'occurredAtUtc': '2026-08-11T10:35:00Z',
  'receivedAtUtc': '2026-08-11T10:36:00Z',
  'updatedBy': null,
  'updatedAtUtc': null,
};

final _timelineJson = {
  'externalId': 'event-id',
  'eventTypeId': 2,
  'eventTypeName': 'ProjectVisitCompleted',
  'title': 'Visita finalizada',
  'description': 'Se verificó el avance del segundo piso.',
  'occurredAtUtc': '2026-08-11T11:00:00Z',
  'createdBy': {'externalId': 'seller-id', 'name': 'Carlos Gómez'},
  'relatedEntityType': 'Visit',
  'relatedEntityId': 22,
  'metadataJson': null,
  'visitExternalId': 'visit-id',
};

final _reminderJson = {
  'id': 1,
  'externalId': 'reminder-id',
  'text': 'Confirmar materiales',
  'reminderAtUtc': '2026-08-18T14:00:00Z',
  'assignedTo': {'externalId': 'seller-id', 'name': 'Carlos Gómez'},
  'completed': false,
};
