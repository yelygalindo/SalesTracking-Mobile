import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/attachment/project_attachment.dart';
import 'package:urbantrack/ui/history/visit_photo_strip.dart';

void main() {
  testWidgets('shows up to three image attachments and the remaining count', (
    tester,
  ) async {
    final attachments = [
      for (var index = 1; index <= 4; index++)
        _attachment(
          externalId: 'photo-$index',
          contentType: 'image/jpeg',
          downloadUrl: 'https://files.example.test/photo-$index.jpg',
        ),
      _attachment(
        externalId: 'document',
        contentType: 'application/pdf',
        downloadUrl: 'https://files.example.test/document.pdf',
      ),
      _attachment(
        externalId: 'missing-url',
        contentType: 'image/jpeg',
        downloadUrl: null,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VisitPhotoStrip(
            attachments: attachments,
            imageProvider: (_) => MemoryImage(
              base64Decode(
                'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
                'AAAADUlEQVR42mNk+M/wHwAF/gL+Zf8VAAAAAElFTkSuQmCC',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('visit-photo-photo-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('visit-photo-photo-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('visit-photo-photo-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('visit-photo-photo-4')), findsNothing);
    expect(find.byKey(const ValueKey('visit-photo-document')), findsNothing);
    expect(find.text('+1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

ProjectAttachment _attachment({
  required String externalId,
  required String contentType,
  required String? downloadUrl,
}) => ProjectAttachment(
  externalId: externalId,
  fileName: externalId,
  contentType: contentType,
  sizeBytes: 100,
  attachmentType: 'Photo',
  caption: null,
  isCover: false,
  downloadUrl: downloadUrl,
  createdAtUtc: DateTime.utc(2026, 8, 17),
  visitExternalId: 'visit-id',
);
