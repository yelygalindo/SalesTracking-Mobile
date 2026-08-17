import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:urbantrack/data/models/attachment/attachment_source_file.dart';
import 'package:urbantrack/data/services/project_attachment_service.dart';

void main() {
  test('parses upload options and project attachments', () async {
    final service = ProjectAttachmentService(
      Uri.parse('https://api.example.test'),
      MockClient((request) async {
        if (request.url.path == '/api/project-attachments/options') {
          return http.Response(
            jsonEncode({
              'maxFileSizeBytes': 5000000,
              'attachmentTypes': [
                {
                  'value': 'photo',
                  'label': 'Fotografía',
                  'description': 'Evidencia visual',
                },
              ],
              'acceptedFormats': [
                {
                  'description': 'JPEG',
                  'extensions': ['.jpg'],
                  'contentTypes': ['image/jpeg'],
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(
          jsonEncode([
            {
              'externalId': 'attachment-id',
              'fileName': 'photo.jpg',
              'contentType': 'image/jpeg',
              'sizeBytes': 4,
              'attachmentType': 'photo',
              'caption': 'Fachada',
              'isCover': false,
              'downloadUrl': 'https://files.example.test/photo.jpg',
              'createdAtUtc': '2026-08-07T17:00:00Z',
              'visitExternalId': 'visit-id',
            },
          ]),
          200,
        );
      }),
    );

    final options = await service.getOptions('access-token');
    final attachments = await service.getAttachments(
      'access-token',
      'project-id',
    );

    expect(options.maxFileSizeBytes, 5000000);
    expect(options.attachmentTypes.single.value, 'photo');
    expect(attachments.single.visitExternalId, 'visit-id');
  });

  test('uploads the documented multipart fields', () async {
    final directory = await Directory.systemTemp.createTemp('urbantrack_test_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}photo.jpg');
    await file.writeAsBytes([1, 2, 3, 4]);
    late http.Request captured;
    final service = ProjectAttachmentService(
      Uri.parse('https://api.example.test'),
      MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode({'id': 'file-id'}), 201);
      }),
    );

    await service.upload(
      'access-token',
      projectExternalId: 'project-id',
      source: AttachmentSourceFile(
        path: file.path,
        fileName: 'stable-photo.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 4,
      ),
      attachmentType: 'photo',
      clientRequestId: '123e4567-e89b-12d3-a456-426614174000',
      occurredAtUtc: DateTime.utc(2026, 8, 17, 15, 30),
      visitExternalId: 'visit-id',
      caption: 'Fachada',
    );

    final body = latin1.decode(captured.bodyBytes);
    expect(captured.method, 'POST');
    expect(captured.url.path, '/api/projects/project-id/attachments');
    expect(captured.headers['content-type'], contains('multipart/form-data'));
    expect(body, contains('name="AttachmentType"'));
    expect(body, contains('photo'));
    expect(body, contains('name="VisitExternalId"'));
    expect(body, contains('visit-id'));
    expect(body, contains('name="ClientRequestId"'));
    expect(body, contains('123e4567-e89b-12d3-a456-426614174000'));
    expect(body, contains('name="OccurredAtUtc"'));
    expect(body, contains('2026-08-17T15:30:00.000Z'));
    expect(body, contains('filename="stable-photo.jpg"'));
    expect(body.toLowerCase(), contains('content-type: image/jpeg'));
  });
}
