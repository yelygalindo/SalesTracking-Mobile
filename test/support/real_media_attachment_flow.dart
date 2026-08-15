import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:urbantrack/data/models/attachment/attachment_save_result.dart';
import 'package:urbantrack/data/models/attachment/attachment_source_file.dart';
import 'package:urbantrack/data/models/attachment/attachment_upload_options.dart';
import 'package:urbantrack/data/models/attachment/project_attachment.dart';
import 'package:urbantrack/data/repositories/offline_first_project_attachment_repository.dart';
import 'package:urbantrack/data/repositories/project_attachment_repository.dart';
import 'package:urbantrack/data/services/attachment_picker_service.dart';
import 'package:urbantrack/data/services/image_picker_attachment_service.dart';
import 'package:urbantrack/data/storage/device_attachment_file_store.dart';
import 'package:urbantrack/ui/attachments/project_attachment_screen.dart';

import 'project_attachment_test_doubles.dart';
import 'workday_test_doubles.dart';

enum RealMediaSource { camera, gallery }

Future<void> runRealMediaAttachmentFlow(
  WidgetTester tester,
  RealMediaSource source,
) async {
  final local = MemoryAttachmentLocalStore();
  const files = DeviceAttachmentFileStore();
  final picker = _ObservedRealAttachmentPickerService();
  var requestSequence = 0;
  final repository = OfflineFirstProjectAttachmentRepository(
    _OptionsOnlyAttachmentRepository(),
    local,
    NoopVisitLocalStore(),
    files,
    DisconnectedNetworkStatusService(),
    requestId: () => 'real-media-${source.name}-${requestSequence++}',
    now: () => DateTime.utc(2026, 8, 15, 15),
  );
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: FilledButton(
              key: const ValueKey('open-real-media-test'),
              onPressed: () => context.push('/attachments'),
              child: const Text('Abrir prueba de evidencia'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/attachments',
        builder: (context, state) => ProjectAttachmentScreen(
          repository: repository,
          projectExternalId: 'project-real-media-test',
          visitExternalId: 'visit-real-media-test',
          pickerService: picker,
        ),
      ),
    ],
  );
  addTearDown(() async {
    router.dispose();
    for (final operation in local.operations) {
      await files.delete(operation.source.path);
    }
  });

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('open-real-media-test')));
  await tester.pumpAndSettle();

  final pickerKey = switch (source) {
    RealMediaSource.camera => const ValueKey('take-photo-button'),
    RealMediaSource.gallery => const ValueKey('pick-gallery-button'),
  };
  debugPrint('REAL_MEDIA_TEST: opening ${source.name} picker');
  await tester.tap(find.byKey(pickerKey));
  await tester.pump();

  await _waitForPreview(tester, picker);
  debugPrint('REAL_MEDIA_TEST: ${source.name} selection received');

  await tester.enterText(
    find.byKey(const ValueKey('attachment-caption')),
    'Validación física ${source.name}',
  );
  final saveButton = find.byKey(const ValueKey('save-attachments-button'));
  await tester.ensureVisible(saveButton);
  await tester.tap(saveButton);
  await tester.pumpAndSettle();

  expect(find.byKey(const ValueKey('open-real-media-test')), findsOneWidget);
  expect(local.operations, isNotEmpty);
  for (final operation in local.operations) {
    expect(operation.projectExternalId, 'project-real-media-test');
    expect(operation.visitExternalId, 'visit-real-media-test');
    expect(operation.caption, 'Validación física ${source.name}');
    expect(operation.source.sizeBytes, greaterThan(0));
    expect(await File(operation.source.path).exists(), isTrue);
    expect(
      operation.source.path,
      contains(
        '${Platform.pathSeparator}pending_attachments${Platform.pathSeparator}',
      ),
    );
  }
  debugPrint(
    'REAL_MEDIA_TEST: ${local.operations.length} ${source.name} file(s) persisted offline',
  );
}

Future<void> _waitForPreview(
  WidgetTester tester,
  _ObservedRealAttachmentPickerService picker,
) async {
  final preview = find.byKey(const ValueKey('attachment-preview-0'));
  final deadline = DateTime.now().add(const Duration(minutes: 5));
  while (!picker.completed && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await tester.pump();
  }
  await tester.pump();
  expect(picker.completed, isTrue, reason: 'El selector nativo no respondió.');
  expect(picker.error, isNull, reason: 'El selector nativo devolvió un error.');
  expect(
    preview,
    findsOneWidget,
    reason: 'El selector nativo terminó sin devolver una imagen válida.',
  );
}

class _ObservedRealAttachmentPickerService implements AttachmentPickerService {
  final AttachmentPickerService _delegate = ImagePickerAttachmentService();
  bool completed = false;
  Object? error;

  @override
  Future<List<AttachmentSourceFile>> recoverLostImages() =>
      _delegate.recoverLostImages();

  @override
  Future<AttachmentSourceFile?> takePhoto() => _observe(
    _delegate.takePhoto,
    const <AttachmentSourceFile>[],
  ).then((images) => images.firstOrNull);

  @override
  Future<List<AttachmentSourceFile>> pickFromGallery() =>
      _observe(_delegate.pickFromGallery, const <AttachmentSourceFile>[]);

  Future<List<AttachmentSourceFile>> _observe<T>(
    Future<T> Function() action,
    List<AttachmentSourceFile> empty,
  ) async {
    completed = false;
    error = null;
    try {
      final result = await action();
      return switch (result) {
        AttachmentSourceFile value => [value],
        List<AttachmentSourceFile> values => values,
        _ => empty,
      };
    } catch (caught) {
      error = caught;
      rethrow;
    } finally {
      completed = true;
    }
  }
}

class _OptionsOnlyAttachmentRepository implements ProjectAttachmentRepository {
  @override
  Future<AttachmentUploadOptions> getOptions() async =>
      const AttachmentUploadOptions(
        maxFileSizeBytes: 0,
        attachmentTypes: [
          AttachmentTypeOption(
            value: 'photo',
            label: 'Fotografía',
            description: 'Evidencia fotográfica',
          ),
        ],
        acceptedFormats: [],
      );

  @override
  Future<List<ProjectAttachment>> getAttachments(
    String projectExternalId,
  ) async => const [];

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<AttachmentSaveResult> saveAttachments({
    required String projectExternalId,
    required List<AttachmentSourceFile> sources,
    required String attachmentType,
    String? visitExternalId,
    String? caption,
    bool isCover = false,
  }) => throw StateError('La prueba física no debe llamar al servidor.');

  @override
  Future<void> syncPending() async {}
}
