import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/common/location_sample.dart';
import 'package:urbantrack/data/models/common/resource_creation_result.dart';
import 'package:urbantrack/data/models/customer/customer_detail.dart';
import 'package:urbantrack/data/models/customer/customer_input.dart';
import 'package:urbantrack/data/models/customer/customer_page.dart';
import 'package:urbantrack/data/models/customer/customer_status.dart';
import 'package:urbantrack/data/models/customer/customer_summary.dart';
import 'package:urbantrack/data/models/project/project_detail.dart';
import 'package:urbantrack/data/models/project/project_input.dart';
import 'package:urbantrack/data/models/project/project_note.dart';
import 'package:urbantrack/data/models/project/project_page.dart';
import 'package:urbantrack/data/models/project/project_reminder.dart';
import 'package:urbantrack/data/models/project/project_status.dart';
import 'package:urbantrack/data/models/project/project_summary.dart';
import 'package:urbantrack/data/models/project/project_timeline_item.dart';
import 'package:urbantrack/data/models/project/project_timeline_page.dart';
import 'package:urbantrack/data/models/common/user_reference.dart';
import 'package:urbantrack/data/repositories/customer_repository.dart';
import 'package:urbantrack/data/repositories/project_repository.dart';
import 'package:urbantrack/data/services/location_service.dart';
import 'package:urbantrack/ui/projects/project_detail_view_model.dart';
import 'package:urbantrack/ui/projects/project_form_view_model.dart';
import 'package:urbantrack/ui/projects/project_list_view_model.dart';

void main() {
  test('filters and paginates the project list', () async {
    final projects = _RecordingProjectRepository();
    final viewModel = ProjectListViewModel(
      projects,
      _CustomerOptionsRepository(),
      pageSize: 1,
    );

    await viewModel.initialize();
    await viewModel.selectStatus(2);
    await viewModel.selectCustomer('customer-id');
    await viewModel.loadMore();

    expect(viewModel.customerOptions.single.externalId, 'customer-id');
    expect(projects.statuses.last, '2');
    expect(projects.customerIds.last, 'customer-id');
    expect(viewModel.items.length, 2);
  });

  test('creates a project with GPS and a stable request id', () async {
    final projects = _RecordingProjectRepository();
    final viewModel = ProjectFormViewModel(
      projects,
      _CustomerOptionsRepository(),
      _FixedLocationService(),
      requestId: () => 'project-request-id',
    );
    await viewModel.initialize();
    await viewModel.captureLocation();

    final saved = await viewModel.save(
      name: 'Obra Norte',
      description: 'Edificio residencial',
      customerExternalId: 'customer-id',
      estimatedAmount: 185000,
      startDateUtc: DateTime.utc(2026, 8, 1),
      expectedCloseDateUtc: DateTime.utc(2026, 10, 30),
      progressPercentage: 45,
      address: 'Av. Banzer',
    );

    expect(saved, isTrue);
    expect(projects.createdRequestId, 'project-request-id');
    expect(projects.createdInput?.latitude, -17.75);
    expect(viewModel.savedExternalId, 'project-id');
  });

  test('updates a project with the loaded concurrency timestamp', () async {
    final projects = _RecordingProjectRepository();
    final viewModel = ProjectFormViewModel(
      projects,
      _CustomerOptionsRepository(),
      _FixedLocationService(),
      externalId: 'project-id',
    );
    await viewModel.initialize();

    expect(projects.lastRequireFresh, isTrue);

    expect(
      await viewModel.save(
        name: 'Obra Norte actualizada',
        description: 'Edificio residencial',
        customerExternalId: 'customer-id',
        estimatedAmount: 185000,
        startDateUtc: DateTime.utc(2026, 8, 1),
        expectedCloseDateUtc: DateTime.utc(2026, 10, 30),
        progressPercentage: 55,
        address: 'Av. Banzer',
      ),
      isTrue,
    );

    expect(
      projects.updatedInput?.expectedUpdatedAtUtc,
      DateTime.utc(2026, 8, 18, 14, 30, 0, 123, 456),
    );
    expect(
      projects.updatedInput?.expectedUpdatedAtUtcToken,
      '2026-08-18T14:30:00.1234567Z',
    );
  });

  test(
    'blocks project updates when the API omits the concurrency token',
    () async {
      final projects = _RecordingProjectRepository(
        detail: ProjectDetail.fromJson({
          ..._detail.toJson(),
          'updatedAtUtc': null,
        }),
      );
      final viewModel = ProjectFormViewModel(
        projects,
        _CustomerOptionsRepository(),
        _FixedLocationService(),
        externalId: 'project-id',
      );

      await viewModel.initialize();

      expect(viewModel.canSave, isFalse);
      expect(viewModel.errorMessage, contains('versión actual'));
      expect(
        await viewModel.save(
          name: 'Obra Norte actualizada',
          description: 'Edificio residencial',
          customerExternalId: 'customer-id',
          estimatedAmount: 185000,
          startDateUtc: DateTime.utc(2026, 8, 1),
          expectedCloseDateUtc: DateTime.utc(2026, 10, 30),
          progressPercentage: 55,
          address: 'Av. Banzer',
        ),
        isFalse,
      );
      expect(projects.updatedInput, isNull);
    },
  );

  test('loads project detail and changes its status', () async {
    final projects = _RecordingProjectRepository();
    final occurredAtUtc = DateTime.utc(2026, 8, 11, 14, 20);
    final viewModel = ProjectDetailViewModel(
      projects,
      'project-id',
      requestId: () => 'note-request-id',
      now: () => occurredAtUtc,
    );

    await viewModel.load();

    expect(viewModel.project?.name, 'Obra Norte');
    expect(viewModel.project?.progressPercentage, 45);
    expect(viewModel.statusOptions.map((status) => status.label), [
      'Activo',
      'Completado',
    ]);
    expect(viewModel.notes.single.content, 'Avance confirmado');
    expect(viewModel.reminders.single.text, 'Confirmar materiales');
    expect(viewModel.timeline.single.title, 'Nota agregada');

    final noteAdded = await viewModel.addNote('  Revisar materiales  ');

    expect(noteAdded, isTrue);
    expect(projects.addedNoteContent, 'Revisar materiales');
    expect(projects.addedNoteRequestId, 'note-request-id');
    expect(projects.addedNoteOccurredAtUtc, occurredAtUtc);

    final reminderAtUtc = DateTime.utc(2026, 8, 18, 14);
    final reminderAdded = await viewModel.addReminder(
      text: '  Llamar al encargado  ',
      reminderAtUtc: reminderAtUtc,
    );
    expect(reminderAdded, isTrue);
    expect(projects.addedReminderText, 'Llamar al encargado');
    expect(projects.addedReminderAtUtc, reminderAtUtc);

    final reminderCompleted = await viewModel.completeReminder(
      'project-reminder-id',
    );
    expect(reminderCompleted, isTrue);
    expect(projects.completedReminderId, 'project-reminder-id');

    final changed = await viewModel.changeStatus(
      const ProjectStatus(value: 4, label: 'Completado'),
    );

    expect(changed, isTrue);
    expect(projects.changedStatusId, 4);
    expect(viewModel.project?.status, 'Completado');
  });
}

class _RecordingProjectRepository implements ProjectRepository {
  _RecordingProjectRepository({ProjectDetail? detail})
    : detail = detail ?? _detail;

  final ProjectDetail detail;
  final List<String?> statuses = [];
  final List<String?> customerIds = [];
  ProjectInput? createdInput;
  ProjectInput? updatedInput;
  String? createdRequestId;
  int? changedStatusId;
  String currentStatus = 'Activo';
  String? addedNoteContent;
  String? addedNoteRequestId;
  DateTime? addedNoteOccurredAtUtc;
  final List<ProjectReminder> reminders = [_projectReminder];
  String? addedReminderText;
  DateTime? addedReminderAtUtc;
  String? completedReminderId;
  bool? lastRequireFresh;

  @override
  Future<ResourceCreationResult> addReminder(
    String projectExternalId, {
    required String text,
    required DateTime reminderAtUtc,
    required String clientRequestId,
    String? assignedToId,
  }) async {
    addedReminderText = text;
    addedReminderAtUtc = reminderAtUtc;
    reminders.add(
      ProjectReminder(
        id: reminders.length + 1,
        externalId: 'project-reminder-${reminders.length + 1}',
        text: text,
        reminderAtUtc: reminderAtUtc,
        assignedTo: _projectAuthor,
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
    completedReminderId = reminderExternalId;
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
    addedNoteContent = content;
    addedNoteRequestId = clientRequestId;
    addedNoteOccurredAtUtc = occurredAtUtc;
    return const ResourceCreationResult(id: 'note-id', message: 'Created');
  }

  @override
  Future<ProjectPage> getProjects({
    String? status,
    String? customerId,
    String? sellerId,
    int page = 1,
    int pageSize = 20,
  }) async {
    statuses.add(status);
    customerIds.add(customerId);
    return ProjectPage(
      projects: [_summary(page)],
      page: page,
      pageSize: pageSize,
      totalItems: 2,
      totalPages: 2,
    );
  }

  @override
  Future<ProjectDetail> getProject(
    String externalId, {
    bool requireFresh = false,
  }) async {
    lastRequireFresh = requireFresh;
    return ProjectDetail.fromJson({
      ...detail.toJson(),
      'status': currentStatus,
    });
  }

  @override
  Future<List<ProjectNote>> getNotes(String projectExternalId) async => [
    _projectNote,
  ];

  @override
  Future<List<ProjectStatus>> getStatuses() async => const [
    ProjectStatus(value: 2, label: 'Activo'),
    ProjectStatus(value: 4, label: 'Completado'),
  ];

  @override
  Future<ProjectTimelinePage> getTimeline(
    String projectExternalId, {
    int page = 1,
    int pageSize = 50,
  }) async => ProjectTimelinePage(
    items: [_projectTimelineItem],
    page: page,
    pageSize: pageSize,
    totalItems: 1,
    totalPages: 1,
  );

  @override
  Future<ProjectDetail> createProject(
    ProjectInput input,
    String clientRequestId,
  ) async {
    createdInput = input;
    createdRequestId = clientRequestId;
    return detail;
  }

  @override
  Future<void> updateProject(String externalId, ProjectInput input) async {
    updatedInput = input;
  }

  @override
  Future<void> changeStatus(String externalId, int statusId) async {
    changedStatusId = statusId;
    currentStatus = switch (statusId) {
      4 => 'Completado',
      _ => currentStatus,
    };
  }
}

class _CustomerOptionsRepository implements CustomerRepository {
  @override
  Future<CustomerPage> getCustomers({
    String? status,
    String? externalUserId,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async => CustomerPage(
    customers: [_customer],
    page: 1,
    pageSize: pageSize,
    totalItems: 1,
    totalPages: 1,
  );

  @override
  Future<List<CustomerStatus>> getStatuses() async => const [];

  @override
  Future<CustomerDetail> getCustomer(String externalId) {
    throw UnimplementedError();
  }

  @override
  Future<ResourceCreationResult> createCustomer(
    CustomerInput input,
    String clientRequestId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateCustomer(String externalId, CustomerInput input) async {}

  @override
  Future<void> changeStatus(String externalId, int statusId) async {}

  @override
  Future<ResourceCreationResult> addNote(
    String externalId,
    String text,
    String clientRequestId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ResourceCreationResult> addReminder(
    String externalId, {
    required String text,
    required DateTime reminderAtUtc,
    required String clientRequestId,
    String? assignedToId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> completeReminder(
    String customerExternalId,
    String reminderExternalId,
    String clientRequestId,
  ) {
    throw UnimplementedError();
  }
}

class _FixedLocationService implements LocationService {
  @override
  Future<LocationSample> captureCurrent() async => const LocationSample(
    latitude: -17.75,
    longitude: -63.18,
    accuracyMeters: 6,
  );
}

final _customer = CustomerSummary(
  id: 1,
  externalId: 'customer-id',
  name: 'Ricardo',
  companyName: 'Constructora Horizonte',
  phone: '70010001',
  email: 'seller@example.test',
  status: 'Activo',
  createdAtUtc: DateTime.utc(2026, 8, 1),
  seller: null,
);

ProjectSummary _summary(int index) => ProjectSummary(
  id: index,
  externalId: 'project-$index',
  name: 'Obra $index',
  description: '',
  customerExternalId: 'customer-id',
  customerName: 'Constructora Horizonte',
  sellerExternalId: 'seller-id',
  sellerName: 'Carlos',
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
  id: 4,
  externalId: 'project-id',
  name: 'Obra Norte',
  description: 'Edificio residencial',
  customerExternalId: 'customer-id',
  customerName: 'Constructora Horizonte',
  sellerExternalId: 'seller-id',
  sellerName: 'Carlos',
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
  updatedAtUtc: DateTime.utc(2026, 8, 18, 14, 30),
  updatedAtUtcToken: '2026-08-18T14:30:00.1234567Z',
);

const _projectAuthor = UserReference(externalId: 'seller-id', name: 'Carlos');

final _projectNote = ProjectNote(
  id: 1,
  externalId: 'note-id',
  content: 'Avance confirmado',
  createdBy: _projectAuthor,
  createdAtUtc: DateTime.utc(2026, 8, 11, 10, 30),
  occurredAtUtc: DateTime.utc(2026, 8, 11, 10, 30),
  receivedAtUtc: DateTime.utc(2026, 8, 11, 10, 31),
  updatedBy: null,
  updatedAtUtc: null,
);

final _projectReminder = ProjectReminder(
  id: 1,
  externalId: 'project-reminder-id',
  text: 'Confirmar materiales',
  reminderAtUtc: DateTime.utc(2026, 8, 18, 13),
  assignedTo: _projectAuthor,
  completed: false,
);

final _projectTimelineItem = ProjectTimelineItem(
  externalId: 'event-id',
  eventTypeId: 2,
  eventTypeName: 'ProjectNoteCreated',
  title: 'Nota agregada',
  description: 'Avance confirmado',
  occurredAtUtc: DateTime.utc(2026, 8, 11, 10, 30),
  createdBy: _projectAuthor,
  relatedEntityType: 'ProjectNote',
  relatedEntityId: 1,
  metadataJson: null,
  visitExternalId: null,
);
