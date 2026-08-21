import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/app/urbantrack_app.dart';
import 'package:urbantrack/config/app_environment.dart';
import 'package:urbantrack/data/models/attachment/attachment_source_file.dart';
import 'package:urbantrack/data/models/common/resource_creation_result.dart';
import 'package:urbantrack/data/models/project/project_detail.dart';
import 'package:urbantrack/data/models/project/project_input.dart';
import 'package:urbantrack/data/models/project/project_note.dart';
import 'package:urbantrack/data/models/project/project_page.dart';
import 'package:urbantrack/data/models/project/project_reminder.dart';
import 'package:urbantrack/data/models/project/project_status.dart';
import 'package:urbantrack/data/models/project/project_summary.dart';
import 'package:urbantrack/data/models/project/project_timeline_page.dart';
import 'package:urbantrack/data/models/workday/workday.dart';
import 'package:urbantrack/data/repositories/attachment_sync_repository.dart';
import 'package:urbantrack/data/repositories/offline_first_project_attachment_repository.dart';
import 'package:urbantrack/data/repositories/project_repository.dart';
import 'package:urbantrack/ui/core/branding/urbantrack_brand.dart';

import 'project_attachment_test_doubles.dart';
import 'signed_in_auth_repository.dart';
import 'stateful_visit_repository.dart';
import 'workday_test_doubles.dart';

Future<void> runProjectPhotoLifecycleFlow(WidgetTester tester) async {
  late final Directory tempDirectory;
  late final AttachmentSourceFile cameraSource;
  late final AttachmentSourceFile gallerySource;
  await tester.runAsync(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'urbantrack-photo-flow-',
    );
    cameraSource = await _writeImage(tempDirectory, 'camera.png');
    gallerySource = await _writeImage(tempDirectory, 'gallery.png');
  });
  addTearDown(() async {
    await tester.runAsync(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });
  });
  final picker = FakeAttachmentPickerService(
    cameraImage: cameraSource,
    galleryImages: [gallerySource],
  );
  final visits = StatefulVisitRepository(useLocalIds: true);
  final network = DisconnectedNetworkStatusService();
  final attachmentLocal = MemoryAttachmentLocalStore();
  final attachmentFiles = PassThroughAttachmentFileStore();
  final attachmentRemote = RecordingAttachmentRemoteRepository();
  final attachmentRequestIds = ['camera-photo-id', 'gallery-photo-id'];
  final attachments = OfflineFirstProjectAttachmentRepository(
    attachmentRemote,
    attachmentLocal,
    NoopVisitLocalStore(),
    attachmentFiles,
    network,
    requestId: () => attachmentRequestIds.removeAt(0),
    now: () => DateTime.utc(2026, 8, 14, 15),
  );
  final attachmentSync = AttachmentSyncRepository(attachmentLocal, attachments);
  final workdays = StatefulWorkdayRepository()
    ..current = Workday(
      externalId: 'workday-test-id',
      status: 'open',
      startedAtUtc: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
      startedReceivedAtUtc: DateTime.now().toUtc(),
      startLatitude: -12.0464,
      startLongitude: -77.0428,
    );

  await tester.pumpWidget(
    UrbanTrackApp(
      brand: UrbanTrackBrand.config,
      environment: const AppEnvironment(apiBaseUrl: 'https://example.test'),
      authRepository: SignedInAuthRepository(),
      workdayRepository: workdays,
      locationService: FixedLocationService(),
      networkStatusService: network,
      syncRepository: attachmentSync,
      customerRepository: EmptyCustomerRepository(),
      projectRepository: _ProjectPhotoRepository(),
      visitRepository: visits,
      attachmentRepository: attachments,
      historyRepository: EmptyHistoryRepository(),
      attachmentPickerService: picker,
    ),
  );
  await _pumpUi(tester);

  await tester.tap(find.byKey(const ValueKey('primary-nav-projects')));
  await _pumpUi(tester);

  final projectCard = find.byKey(
    const ValueKey('project-card-project-test-id'),
  );
  expect(projectCard, findsOneWidget);
  await tester.tap(projectCard);
  await _pumpUi(tester);

  final startVisit = find.byKey(const ValueKey('start-visit-button'));
  await tester.ensureVisible(startVisit);
  await tester.tap(startVisit);
  await _pumpUi(tester);
  await tester.enterText(
    find.byKey(const ValueKey('visit-check-in-note')),
    'Documentar avance de obra',
  );
  await tester.tap(find.byKey(const ValueKey('confirm-visit-check-in')));
  await _pumpUi(tester);

  expect(visits.current?.externalId, startsWith('local:'));
  expect(visits.checkInRequestId, isNotEmpty);

  final addPhotos = find.byKey(const ValueKey('add-visit-photos-button'));
  await tester.ensureVisible(addPhotos);
  await tester.tap(addPhotos);
  await _pumpUi(tester);

  final saveButton = find.byKey(const ValueKey('save-attachments-button'));
  await tester.tap(saveButton);
  await _pumpUi(tester);
  expect(find.text('Agrega al menos una fotografía.'), findsOneWidget);
  expect(attachmentLocal.operations, isEmpty);

  await tester.tap(find.byKey(const ValueKey('take-photo-button')));
  await _pumpUi(tester);
  await tester.tap(find.byKey(const ValueKey('pick-gallery-button')));
  await _pumpUi(tester);
  expect(picker.cameraCalls, 1);
  expect(picker.galleryCalls, 1);

  await tester.enterText(
    find.byKey(const ValueKey('attachment-caption')),
    'Avance de fachada',
  );
  await tester.ensureVisible(saveButton);
  await _pumpUi(tester);
  await tester.tap(saveButton);
  await _pumpUi(tester);

  expect(find.text('Fotografías guardadas.'), findsOneWidget);
  expect(attachmentFiles.persisted, hasLength(2));
  expect(attachmentRemote.saveCalls, 0);
  expect(attachmentLocal.operations, hasLength(2));
  expect(
    attachmentLocal.operations.map((operation) => operation.source.fileName),
    ['camera.png', 'gallery.png'],
  );
  expect(
    attachmentLocal.operations.map((operation) => operation.caption).toSet(),
    {'Avance de fachada'},
  );
  expect(
    attachmentLocal.operations.map((operation) => operation.visitExternalId),
    everyElement(visits.current!.externalId),
  );

  final pending = await attachmentSync.getPending();
  expect(pending, hasLength(2));
  expect(
    pending.map((entry) => entry.dependsOnId),
    everyElement(visits.checkInRequestId),
  );
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  for (var frame = 0; frame < 6; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<AttachmentSourceFile> _writeImage(
  Directory directory,
  String fileName,
) async {
  final file = File('${directory.path}${Platform.pathSeparator}$fileName');
  final bytes = base64Decode(_onePixelPng);
  await file.writeAsBytes(bytes, flush: true);
  return AttachmentSourceFile(
    path: file.path,
    fileName: fileName,
    contentType: 'image/png',
    sizeBytes: bytes.length,
  );
}

class _ProjectPhotoRepository implements ProjectRepository {
  @override
  Future<ResourceCreationResult> addReminder(
    String projectExternalId, {
    required String text,
    required DateTime reminderAtUtc,
    required String clientRequestId,
    String? assignedToId,
  }) async =>
      const ResourceCreationResult(id: 'reminder-id', message: 'Created');

  @override
  Future<void> completeReminder(
    String projectExternalId,
    String reminderExternalId,
    String clientRequestId,
  ) async {}

  @override
  Future<List<ProjectReminder>> getReminders(
    String projectExternalId, {
    bool? completed,
  }) async => const [];

  @override
  Future<ProjectPage> getProjects({
    String? status,
    String? customerId,
    String? sellerId,
    int page = 1,
    int pageSize = 20,
  }) async => ProjectPage(
    projects: const [_projectSummary],
    page: page,
    pageSize: pageSize,
    totalItems: 1,
    totalPages: 1,
  );

  @override
  Future<ProjectDetail> getProject(
    String externalId, {
    bool requireFresh = false,
  }) async => _projectDetail;

  @override
  Future<List<ProjectStatus>> getStatuses() async => const [
    ProjectStatus(value: 1, label: 'En progreso'),
  ];

  @override
  Future<List<ProjectNote>> getNotes(String projectExternalId) async =>
      const [];

  @override
  Future<ProjectTimelinePage> getTimeline(
    String projectExternalId, {
    int page = 1,
    int pageSize = 50,
  }) async => ProjectTimelinePage(
    items: const [],
    page: page,
    pageSize: pageSize,
    totalItems: 0,
    totalPages: 0,
  );

  @override
  Future<ResourceCreationResult> addNote(
    String projectExternalId, {
    required String content,
    required String clientRequestId,
    required DateTime occurredAtUtc,
  }) async => const ResourceCreationResult(id: 'note-id', message: 'Created');

  @override
  Future<void> changeStatus(String externalId, int statusId) async {}

  @override
  Future<ProjectDetail> createProject(
    ProjectInput input,
    String clientRequestId,
  ) async => _projectDetail;

  @override
  Future<void> updateProject(String externalId, ProjectInput input) async {}
}

const _projectSummary = ProjectSummary(
  id: 1,
  externalId: 'project-test-id',
  name: 'Obra Integración',
  description: 'Proyecto de prueba',
  customerExternalId: 'customer-test-id',
  customerName: 'Cliente Integración',
  sellerExternalId: 'seller-test-id',
  sellerName: 'Vendedor de prueba',
  status: 'En progreso',
  estimatedAmount: 10000,
  startDateUtc: null,
  expectedCloseDateUtc: null,
  progressPercentage: 40,
  actualCloseDateUtc: null,
  address: 'Av. de prueba',
  latitude: -12.0464,
  longitude: -77.0428,
  createdAtUtc: null,
);

const _projectDetail = ProjectDetail(
  id: 1,
  externalId: 'project-test-id',
  name: 'Obra Integración',
  description: 'Proyecto de prueba',
  customerExternalId: 'customer-test-id',
  customerName: 'Cliente Integración',
  sellerExternalId: 'seller-test-id',
  sellerName: 'Vendedor de prueba',
  status: 'En progreso',
  estimatedAmount: 10000,
  startDateUtc: null,
  expectedCloseDateUtc: null,
  progressPercentage: 40,
  actualCloseDateUtc: null,
  address: 'Av. de prueba',
  latitude: -12.0464,
  longitude: -77.0428,
  createdAtUtc: null,
);

const _onePixelPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+'
    'A8AAQUBAScY42YAAAAASUVORK5CYII=';
