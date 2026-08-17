import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:urbantrack/data/services/history_service.dart';

void main() {
  test(
    'loads seller timeline with documented date and pagination filters',
    () async {
      final service = HistoryService(
        Uri.parse('https://api.example.test'),
        MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/sellers/seller-id/timeline');
          expect(request.url.queryParameters, {
            'From': '2026-08-04T00:00:00.000Z',
            'To': '2026-08-05T00:00:00.000Z',
            'Page': '2',
            'PageSize': '30',
          });
          expect(request.headers['authorization'], 'Bearer access-token');
          return http.Response(
            jsonEncode({
              'items': [_timelineJson],
              'pagination': {
                'page': 2,
                'pageSize': 30,
                'totalItems': 31,
                'totalPages': 2,
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final page = await service.getSellerTimeline(
        'access-token',
        'seller-id',
        from: DateTime.utc(2026, 8, 4),
        to: DateTime.utc(2026, 8, 5),
        page: 2,
      );

      expect(page.items.single.title, 'Visita finalizada · Obra Norte');
      expect(page.items.single.occurredAtUtc, DateTime.utc(2026, 8, 4, 11));
      expect(page.totalItems, 31);
      expect(page.totalPages, 2);
    },
  );

  test(
    'loads the project visit contract and preserves checkout details',
    () async {
      final service = HistoryService(
        Uri.parse('https://api.example.test'),
        MockClient((request) async {
          expect(request.url.path, '/api/projects/project-id/visits');
          expect(request.url.queryParameters, {
            'SellerExternalId': 'seller-id',
            'From': '2026-08-01T00:00:00.000Z',
            'To': '2026-08-08T00:00:00.000Z',
          });
          return http.Response(
            jsonEncode([_visitJson]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final visits = await service.getProjectVisits(
        'access-token',
        'project-id',
        sellerExternalId: 'seller-id',
        from: DateTime.utc(2026, 8, 1),
        to: DateTime.utc(2026, 8, 8),
      );

      expect(visits.single.projectName, 'Obra Norte');
      expect(visits.single.result, 'Cotización entregada');
      expect(visits.single.isOpen, isFalse);
      expect(visits.single.duration, const Duration(minutes: 55));
    },
  );

  test('loads attachments for a visit', () async {
    final service = HistoryService(
      Uri.parse('https://api.example.test'),
      MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/visits/visit-id/attachments');
        expect(request.headers['authorization'], 'Bearer access-token');
        return http.Response(
          jsonEncode([_attachmentJson]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final attachments = await service.getVisitAttachments(
      'access-token',
      'visit-id',
    );

    expect(attachments.single.externalId, 'attachment-id');
    expect(attachments.single.isImage, isTrue);
    expect(
      attachments.single.downloadUrlExpiresAtUtc,
      DateTime.utc(2026, 8, 4, 12),
    );
  });
}

final _timelineJson = {
  'externalId': 'event-id',
  'eventType': 'ProjectVisitCheckedOut',
  'resourceType': 'ProjectVisit',
  'resourceExternalId': 'visit-id',
  'title': 'Visita finalizada · Obra Norte',
  'description': 'Resultado: Cotización entregada',
  'occurredAtUtc': '2026-08-04T11:00:00Z',
};

final _visitJson = {
  'externalId': 'visit-id',
  'projectExternalId': 'project-id',
  'projectName': 'Obra Norte',
  'customerExternalId': 'customer-id',
  'customerName': 'Constructora Horizonte',
  'visitedAtUtc': '2026-08-03T14:10:00Z',
  'checkInReceivedAtUtc': '2026-08-03T14:10:02Z',
  'latitude': -17.7833,
  'longitude': -63.1821,
  'notes': 'Revisar avance',
  'checkOutAtUtc': '2026-08-03T15:05:00Z',
  'checkOutReceivedAtUtc': '2026-08-03T15:05:01Z',
  'checkOutLatitude': -17.7834,
  'checkOutLongitude': -63.1822,
  'checkOutNote': 'Revisar precios el viernes',
  'result': 'Cotización entregada',
  'sellerExternalId': 'seller-id',
  'sellerName': 'Carlos Gómez',
};

final _attachmentJson = {
  'externalId': 'attachment-id',
  'fileName': 'avance.jpg',
  'contentType': 'image/jpeg',
  'sizeBytes': 2048,
  'attachmentType': 'Photo',
  'caption': 'Avance',
  'isCover': false,
  'downloadUrl': 'https://files.example.test/avance.jpg',
  'downloadUrlExpiresAtUtc': '2026-08-04T12:00:00Z',
  'createdAtUtc': '2026-08-04T11:00:00Z',
  'visitExternalId': 'visit-id',
};
