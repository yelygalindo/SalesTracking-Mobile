import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/project/project_detail.dart';
import 'package:urbantrack/data/models/project/project_input.dart';
import 'package:urbantrack/data/models/project/project_note.dart';
import 'package:urbantrack/data/models/project/project_page.dart';
import 'package:urbantrack/data/models/project/project_reminder.dart';
import 'package:urbantrack/data/models/project/project_summary.dart';
import 'package:urbantrack/data/models/project/project_status.dart';
import 'package:urbantrack/data/models/project/project_timeline_item.dart';
import 'package:urbantrack/data/models/project/project_timeline_page.dart';
import 'package:urbantrack/data/models/common/resource_creation_result.dart';
import 'package:urbantrack/data/models/common/user_reference.dart';
import 'package:urbantrack/data/repositories/project_repository.dart';
import 'package:urbantrack/ui/core/branding/brand_scope.dart';
import 'package:urbantrack/ui/core/branding/urbantrack_brand.dart';
import 'package:urbantrack/ui/projects/project_detail_screen.dart';
import 'package:urbantrack/ui/projects/project_form_screen.dart';
import 'package:urbantrack/ui/projects/project_list_screen.dart';

import '../../support/workday_test_doubles.dart';

void main() {
  testWidgets('renders the project list on phone and tablet', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      BrandScope(
        brand: UrbanTrackBrand.config,
        child: MaterialApp(
          home: ProjectListScreen(
            projectRepository: _ProjectScreenRepository(),
            customerRepository: EmptyCustomerRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Obra Norte'), findsOneWidget);
    expect(find.text('Avance 45%'), findsNWidgets(2));
    expect(find.text('Estado'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(const Size(1024, 900));
    await tester.pumpAndSettle();
    expect(find.text('Residencial Sur'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders project detail and responsive form', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _ProjectScreenRepository();

    await tester.pumpWidget(
      BrandScope(
        brand: UrbanTrackBrand.config,
        child: MaterialApp(
          home: ProjectDetailScreen(
            repository: repository,
            visitRepository: EmptyVisitRepository(),
            externalId: 'project-1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('edit-project-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('map-project-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('project-visits-button')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('change-project-status-button')),
      findsOneWidget,
    );
    expect(find.text('Bs 185000.00'), findsOneWidget);
    final completeReminderButton = find.byKey(
      const ValueKey('complete-project-reminder-project-reminder-1'),
    );
    await tester.ensureVisible(completeReminderButton);
    await tester.pumpAndSettle();
    expect(find.text('Confirmar materiales'), findsOneWidget);
    expect(
      tester.widget<IconButton>(completeReminderButton).onPressed,
      isNotNull,
    );
    await tester.tap(completeReminderButton);
    await tester.pumpAndSettle();
    expect(find.text('Confirmar materiales'), findsNothing);
    expect(tester.takeException(), isNull);

    final changeStatusButton = find.byKey(
      const ValueKey('change-project-status-button'),
    );
    await tester.ensureVisible(changeStatusButton);
    await tester.pumpAndSettle();
    await tester.tap(changeStatusButton);
    await tester.pumpAndSettle();
    expect(find.text('Cambiar estado de la obra'), findsOneWidget);
    expect(find.text('Borrador'), findsOneWidget);
    expect(find.text('En pausa'), findsOneWidget);
    expect(find.text('Perdido'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Perdido'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Seguimiento de la obra'), 500);
    expect(find.text('Avance confirmado'), findsOneWidget);
    expect(find.text('Visita finalizada'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('visit-photo-attachment-id')),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Agregar nota'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar nota'));
    await tester.pumpAndSettle();
    expect(find.text('Nueva nota de obra'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField),
      'Confirmar llegada de materiales',
    );
    await tester.tap(find.text('Guardar nota'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar llegada de materiales'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Seguimiento de la obra'));
    await tester.pumpAndSettle();
    expect(find.text('Notas'), findsOneWidget);
    expect(find.text('Historial'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        home: ProjectFormScreen(
          projectRepository: repository,
          customerRepository: EmptyCustomerRepository(),
          locationService: FixedLocationService(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Registrar obra'), findsOneWidget);
    expect(find.text('Usar ubicación actual'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blocks editing and offers retry without a fresh version token', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _ProjectScreenRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: ProjectFormScreen(
          projectRepository: repository,
          customerRepository: EmptyCustomerRepository(),
          locationService: FixedLocationService(),
          externalId: 'project-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.lastRequireFresh, isTrue);
    expect(find.textContaining('versión actual'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    final saveButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('save-project-button')),
    );
    expect(saveButton.onPressed, isNull);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('versión actual'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _ProjectScreenRepository implements ProjectRepository {
  final List<ProjectNote> notes = [_note];
  final List<ProjectReminder> reminders = [_reminder];
  bool? lastRequireFresh;

  @override
  Future<ResourceCreationResult> addReminder(
    String projectExternalId, {
    required String text,
    required DateTime reminderAtUtc,
    required String clientRequestId,
    String? assignedToId,
  }) async {
    reminders.add(
      ProjectReminder(
        id: reminders.length + 1,
        externalId: 'project-reminder-${reminders.length + 1}',
        text: text,
        reminderAtUtc: reminderAtUtc,
        assignedTo: _author,
        completed: false,
      ),
    );
    return const ResourceCreationResult(
      id: 'project-reminder-new',
      message: 'Created',
    );
  }

  @override
  Future<void> completeReminder(
    String projectExternalId,
    String reminderExternalId,
    String clientRequestId,
  ) async {
    reminders.removeWhere(
      (reminder) => reminder.externalId == reminderExternalId,
    );
  }

  @override
  Future<List<ProjectReminder>> getReminders(
    String projectExternalId, {
    bool? completed,
  }) async => List.unmodifiable(
    reminders.where(
      (reminder) => completed == null || reminder.completed == completed,
    ),
  );

  @override
  Future<ResourceCreationResult> addNote(
    String projectExternalId, {
    required String content,
    required String clientRequestId,
    required DateTime occurredAtUtc,
  }) async {
    notes.insert(
      0,
      ProjectNote(
        id: notes.length + 2,
        externalId: 'note-${notes.length + 2}',
        content: content,
        createdBy: _author,
        createdAtUtc: occurredAtUtc,
        occurredAtUtc: occurredAtUtc,
        receivedAtUtc: occurredAtUtc,
        updatedBy: null,
        updatedAtUtc: null,
      ),
    );
    return const ResourceCreationResult(id: 'note-new', message: 'Created');
  }

  @override
  Future<ProjectPage> getProjects({
    String? status,
    String? customerId,
    String? sellerId,
    int page = 1,
    int pageSize = 20,
  }) async => ProjectPage(
    projects: [_summary(1, 'Obra Norte'), _summary(2, 'Residencial Sur')],
    page: 1,
    pageSize: pageSize,
    totalItems: 2,
    totalPages: 1,
  );

  @override
  Future<ProjectDetail> getProject(
    String externalId, {
    bool requireFresh = false,
  }) async {
    lastRequireFresh = requireFresh;
    return _detail;
  }

  @override
  Future<List<ProjectNote>> getNotes(String projectExternalId) async =>
      List.unmodifiable(notes);

  @override
  Future<List<ProjectStatus>> getStatuses() async => const [
    ProjectStatus(value: 1, label: 'Borrador'),
    ProjectStatus(value: 2, label: 'Activo'),
    ProjectStatus(value: 3, label: 'En pausa'),
    ProjectStatus(value: 4, label: 'Completado'),
    ProjectStatus(value: 5, label: 'Perdido'),
  ];

  @override
  Future<ProjectTimelinePage> getTimeline(
    String projectExternalId, {
    int page = 1,
    int pageSize = 50,
  }) async => ProjectTimelinePage(
    items: [_timelineItem],
    page: page,
    pageSize: pageSize,
    totalItems: 1,
    totalPages: 1,
  );

  @override
  Future<ProjectDetail> createProject(
    ProjectInput input,
    String clientRequestId,
  ) async => _detail;

  @override
  Future<void> updateProject(String externalId, ProjectInput input) async {}

  @override
  Future<void> changeStatus(String externalId, int statusId) async {}
}

ProjectSummary _summary(int id, String name) => ProjectSummary(
  id: id,
  externalId: 'project-$id',
  name: name,
  description: '',
  customerExternalId: 'customer-id',
  customerName: 'Constructora Horizonte',
  sellerExternalId: 'seller-id',
  sellerName: 'Carlos Gómez',
  status: 'Activo',
  estimatedAmount: 185000,
  startDateUtc: DateTime.utc(2026, 8, 1),
  expectedCloseDateUtc: DateTime.utc(2026, 10, 30),
  progressPercentage: 45,
  actualCloseDateUtc: null,
  address: 'Av. Banzer',
  latitude: -17.75,
  longitude: -63.18,
  createdAtUtc: DateTime.utc(2026, 8, 1),
);

final _detail = ProjectDetail(
  id: 1,
  externalId: 'project-1',
  name: 'Obra Norte',
  description: 'Edificio residencial',
  customerExternalId: 'customer-id',
  customerName: 'Constructora Horizonte',
  sellerExternalId: 'seller-id',
  sellerName: 'Carlos Gómez',
  status: 'Activo',
  estimatedAmount: 185000,
  startDateUtc: DateTime.utc(2026, 8, 1),
  expectedCloseDateUtc: DateTime.utc(2026, 10, 30),
  progressPercentage: 45,
  actualCloseDateUtc: null,
  address: 'Av. Banzer',
  latitude: -17.75,
  longitude: -63.18,
  createdAtUtc: DateTime.utc(2026, 8, 1),
);

const _author = UserReference(
  id: 7,
  externalId: 'seller-id',
  name: 'Carlos Gómez',
);

final _note = ProjectNote(
  id: 1,
  externalId: 'note-1',
  content: 'Avance confirmado',
  createdBy: _author,
  createdAtUtc: DateTime.utc(2026, 8, 11, 10, 35),
  occurredAtUtc: DateTime.utc(2026, 8, 11, 10, 35),
  receivedAtUtc: DateTime.utc(2026, 8, 11, 10, 36),
  updatedBy: null,
  updatedAtUtc: null,
);

final _reminder = ProjectReminder(
  id: 1,
  externalId: 'project-reminder-1',
  text: 'Confirmar materiales',
  reminderAtUtc: DateTime.utc(2026, 8, 18, 14),
  assignedTo: _author,
  completed: false,
);

final _timelineItem = ProjectTimelineItem(
  externalId: 'event-1',
  eventTypeId: 2,
  eventTypeName: 'ProjectVisitCompleted',
  title: 'Visita finalizada',
  description: 'Se verificó el avance del segundo piso.',
  occurredAtUtc: DateTime.utc(2026, 8, 11, 11),
  createdBy: _author,
  relatedEntityType: 'Visit',
  relatedEntityId: 22,
  metadataJson: ProjectTimelineMetadata(
    attachmentExternalId: 'attachment-id',
    fileName: 'avance.jpg',
    attachmentType: 'Photo',
    contentType: 'image/jpeg',
    sizeBytes: 2048,
    visitExternalId: 'visit-id',
    downloadUrl: 'https://files.example.test/avance.jpg',
    downloadUrlExpiresAtUtc: DateTime.utc(2026, 8, 11, 12),
  ),
  visitExternalId: 'visit-id',
);
