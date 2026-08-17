import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/project/project_note.dart';
import 'package:urbantrack/data/models/project/project_reminder.dart';
import 'package:urbantrack/data/models/project/project_timeline_page.dart';

void main() {
  test('project note serializes all mobile and server timestamps', () {
    final note = ProjectNote.fromJson(_noteJson);

    expect(note.content, 'Avance confirmado');
    expect(note.createdBy?.name, 'Carlos Gómez');
    expect(note.occurredAtUtc, DateTime.utc(2026, 8, 11, 10, 35));
    expect(note.receivedAtUtc, DateTime.utc(2026, 8, 11, 10, 36));
    expect(ProjectNote.fromJson(note.toJson()).toJson(), note.toJson());
  });

  test('project timeline page serializes its pagination envelope', () {
    final page = ProjectTimelinePage.fromJson({
      'items': [_timelineJson],
      'pagination': {
        'page': 1,
        'pageSize': 50,
        'totalItems': 1,
        'totalPages': 1,
      },
    });

    expect(page.items.single.title, 'Visita finalizada');
    expect(page.items.single.createdBy?.externalId, 'seller-id');
    expect(page.items.single.metadataJson?.fileName, 'avance.jpg');
    expect(page.items.single.metadataJson?.isImage, isTrue);
    expect(page.totalItems, 1);
    expect(ProjectTimelinePage.fromJson(page.toJson()).toJson(), page.toJson());
  });

  test('project timeline also accepts legacy metadata encoded as text', () {
    final item = ProjectTimelinePage.fromJson({
      'items': [
        {
          ..._timelineJson,
          'metadataJson':
              '{"fileName":"legacy.jpg",'
              '"contentType":"image/jpeg",'
              '"downloadUrl":"https://files.example.test/legacy.jpg"}',
        },
      ],
      'pagination': const <String, dynamic>{},
    }).items.single;

    expect(item.metadataJson?.fileName, 'legacy.jpg');
    expect(item.metadataJson?.hasDownloadUrl, isTrue);
  });

  test('project reminder preserves assignment and due date', () {
    final reminder = ProjectReminder.fromJson({
      'id': 1,
      'externalId': 'reminder-id',
      'text': 'Confirmar materiales',
      'reminderAtUtc': '2026-08-18T14:00:00Z',
      'assignedTo': {'externalId': 'seller-id', 'name': 'Carlos Gómez'},
      'completed': false,
    });

    expect(reminder.assignedTo?.externalId, 'seller-id');
    expect(reminder.reminderAtUtc, DateTime.utc(2026, 8, 18, 14));
    expect(
      ProjectReminder.fromJson(reminder.toJson()).toJson(),
      reminder.toJson(),
    );
  });
}

final _noteJson = {
  'id': 1,
  'externalId': 'note-id',
  'content': 'Avance confirmado',
  'createdBy': {'id': 7, 'externalId': 'seller-id', 'name': 'Carlos Gómez'},
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
  'metadataJson': {
    'attachmentExternalId': 'attachment-id',
    'fileName': 'avance.jpg',
    'attachmentType': 'Photo',
    'contentType': 'image/jpeg',
    'sizeBytes': 2048,
    'visitExternalId': 'visit-id',
    'downloadUrl': 'https://files.example.test/avance.jpg',
    'downloadUrlExpiresAtUtc': '2026-08-11T12:00:00Z',
  },
  'visitExternalId': 'visit-id',
};
