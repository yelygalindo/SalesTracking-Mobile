import 'package:urbantrack/data/models/common/resource_creation_result.dart';
import 'package:urbantrack/data/models/common/user_reference.dart';
import 'package:urbantrack/data/models/project/project_detail.dart';
import 'package:urbantrack/data/models/project/project_input.dart';
import 'package:urbantrack/data/models/project/project_note.dart';
import 'package:urbantrack/data/models/project/project_page.dart';
import 'package:urbantrack/data/models/project/project_reminder.dart';
import 'package:urbantrack/data/models/project/project_status.dart';
import 'package:urbantrack/data/models/project/project_summary.dart';
import 'package:urbantrack/data/models/project/project_timeline_item.dart';
import 'package:urbantrack/data/models/project/project_timeline_page.dart';
import 'package:urbantrack/data/repositories/project_repository.dart';

class StatefulProjectRepository implements ProjectRepository {
  StatefulProjectRepository({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const statuses = [
    ProjectStatus(value: 1, label: 'Borrador'),
    ProjectStatus(value: 2, label: 'En progreso'),
    ProjectStatus(value: 3, label: 'Completado'),
  ];

  final DateTime Function() _now;
  final List<ProjectNote> _notes = [];
  final List<ProjectReminder> _reminders = [];
  final List<ProjectTimelineItem> _timeline = [];

  ProjectDetail? project;
  ProjectInput? createdInput;
  ProjectInput? updatedInput;
  String? createRequestId;
  String? noteRequestId;
  DateTime? noteOccurredAtUtc;
  int createCalls = 0;
  int updateCalls = 0;
  int statusCalls = 0;
  int noteCalls = 0;
  int reminderCalls = 0;

  @override
  Future<ProjectPage> getProjects({
    String? status,
    String? customerId,
    String? sellerId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final current = project;
    final matchesStatus =
        status == null || status.isEmpty || current?.status == status;
    final matchesCustomer =
        customerId == null ||
        customerId.isEmpty ||
        current?.customerExternalId == customerId;
    final projects = current != null && matchesStatus && matchesCustomer
        ? [_summary(current)]
        : <ProjectSummary>[];
    return ProjectPage(
      projects: projects,
      page: page,
      pageSize: pageSize,
      totalItems: projects.length,
      totalPages: projects.isEmpty ? 0 : 1,
    );
  }

  @override
  Future<ProjectDetail> getProject(String externalId) async {
    final current = project;
    if (current == null || current.externalId != externalId) {
      throw StateError('Project $externalId does not exist.');
    }
    return current;
  }

  @override
  Future<List<ProjectStatus>> getStatuses() async => statuses;

  @override
  Future<List<ProjectNote>> getNotes(String projectExternalId) async =>
      List.unmodifiable(_notes.reversed);

  @override
  Future<ResourceCreationResult> addNote(
    String projectExternalId, {
    required String content,
    required String clientRequestId,
    required DateTime occurredAtUtc,
  }) async {
    await getProject(projectExternalId);
    noteCalls += 1;
    noteRequestId = clientRequestId;
    noteOccurredAtUtc = occurredAtUtc;
    final note = ProjectNote(
      id: noteCalls,
      externalId: 'project-note-$noteCalls',
      content: content,
      createdBy: _seller,
      createdAtUtc: _now().toUtc(),
      occurredAtUtc: occurredAtUtc.toUtc(),
      receivedAtUtc: _now().toUtc(),
      updatedBy: null,
      updatedAtUtc: null,
    );
    _notes.add(note);
    _addTimeline(
      title: 'Nota agregada',
      description: content,
      occurredAtUtc: occurredAtUtc,
      relatedEntityType: 'ProjectNote',
    );
    return ResourceCreationResult(id: note.externalId, message: 'Created');
  }

  @override
  Future<List<ProjectReminder>> getReminders(
    String projectExternalId, {
    bool? completed,
  }) async {
    await getProject(projectExternalId);
    return _reminders
        .where(
          (reminder) => completed == null || reminder.completed == completed,
        )
        .toList(growable: false);
  }

  @override
  Future<ResourceCreationResult> addReminder(
    String projectExternalId, {
    required String text,
    required DateTime reminderAtUtc,
    required String clientRequestId,
    String? assignedToId,
  }) async {
    await getProject(projectExternalId);
    reminderCalls += 1;
    final reminder = ProjectReminder(
      id: reminderCalls,
      externalId: 'project-reminder-$reminderCalls',
      text: text,
      reminderAtUtc: reminderAtUtc.toUtc(),
      assignedTo: _seller,
      completed: false,
    );
    _reminders.add(reminder);
    return ResourceCreationResult(id: reminder.externalId, message: 'Created');
  }

  @override
  Future<void> completeReminder(
    String projectExternalId,
    String reminderExternalId,
    String clientRequestId,
  ) async {
    await getProject(projectExternalId);
    final index = _reminders.indexWhere(
      (reminder) => reminder.externalId == reminderExternalId,
    );
    if (index < 0) return;
    final reminder = _reminders[index];
    _reminders[index] = ProjectReminder(
      id: reminder.id,
      externalId: reminder.externalId,
      text: reminder.text,
      reminderAtUtc: reminder.reminderAtUtc,
      assignedTo: reminder.assignedTo,
      completed: true,
    );
  }

  @override
  Future<ProjectTimelinePage> getTimeline(
    String projectExternalId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    await getProject(projectExternalId);
    return ProjectTimelinePage(
      items: List.unmodifiable(_timeline.reversed),
      page: page,
      pageSize: pageSize,
      totalItems: _timeline.length,
      totalPages: _timeline.isEmpty ? 0 : 1,
    );
  }

  @override
  Future<ProjectDetail> createProject(
    ProjectInput input,
    String clientRequestId,
  ) async {
    createCalls += 1;
    createdInput = input;
    createRequestId = clientRequestId;
    project = _fromInput(
      input,
      externalId: 'project-integration-id',
      status: statuses.first,
    );
    _addTimeline(
      title: 'Obra creada',
      description: input.name.trim(),
      occurredAtUtc: _now(),
    );
    return project!;
  }

  @override
  Future<void> updateProject(String externalId, ProjectInput input) async {
    final current = await getProject(externalId);
    updateCalls += 1;
    updatedInput = input;
    project = _fromInput(
      input,
      externalId: externalId,
      status: _statusForLabel(current.status),
      createdAtUtc: current.createdAtUtc,
    );
    _addTimeline(
      title: 'Obra actualizada',
      description: input.name.trim(),
      occurredAtUtc: _now(),
    );
  }

  @override
  Future<void> changeStatus(String externalId, int statusId) async {
    final current = await getProject(externalId);
    final status = statuses.firstWhere((item) => item.value == statusId);
    statusCalls += 1;
    project = _copy(current, status: status.label);
    _addTimeline(
      title: 'Estado actualizado',
      description: status.label,
      occurredAtUtc: _now(),
    );
  }

  ProjectDetail _fromInput(
    ProjectInput input, {
    required String externalId,
    required ProjectStatus status,
    DateTime? createdAtUtc,
  }) => ProjectDetail(
    id: 1,
    externalId: externalId,
    name: input.name.trim(),
    description: input.description.trim(),
    customerExternalId: input.customerExternalId,
    customerName: 'Constructora Integración',
    sellerExternalId: input.sellerExternalId ?? _seller.externalId,
    sellerName: _seller.name,
    status: status.label,
    estimatedAmount: input.estimatedAmount,
    startDateUtc: input.startDateUtc,
    expectedCloseDateUtc: input.expectedCloseDateUtc,
    progressPercentage: input.progressPercentage ?? 0,
    actualCloseDateUtc: input.actualCloseDateUtc,
    address: input.address.trim(),
    latitude: input.latitude,
    longitude: input.longitude,
    createdAtUtc: createdAtUtc ?? _now().toUtc(),
  );

  void _addTimeline({
    required String title,
    required String description,
    required DateTime occurredAtUtc,
    String relatedEntityType = 'Project',
  }) {
    final index = _timeline.length + 1;
    _timeline.add(
      ProjectTimelineItem(
        externalId: 'project-event-$index',
        eventTypeId: index,
        eventTypeName: title.replaceAll(' ', ''),
        title: title,
        description: description,
        occurredAtUtc: occurredAtUtc.toUtc(),
        createdBy: _seller,
        relatedEntityType: relatedEntityType,
        relatedEntityId: 1,
        metadataJson: null,
        visitExternalId: null,
      ),
    );
  }

  ProjectStatus _statusForLabel(String label) => statuses.firstWhere(
    (status) => status.label == label,
    orElse: () => statuses.first,
  );
}

ProjectSummary _summary(ProjectDetail project) => ProjectSummary(
  id: project.id,
  externalId: project.externalId,
  name: project.name,
  description: project.description,
  customerExternalId: project.customerExternalId,
  customerName: project.customerName,
  sellerExternalId: project.sellerExternalId,
  sellerName: project.sellerName,
  status: project.status,
  estimatedAmount: project.estimatedAmount,
  startDateUtc: project.startDateUtc,
  expectedCloseDateUtc: project.expectedCloseDateUtc,
  progressPercentage: project.progressPercentage,
  actualCloseDateUtc: project.actualCloseDateUtc,
  address: project.address,
  latitude: project.latitude,
  longitude: project.longitude,
  createdAtUtc: project.createdAtUtc,
);

ProjectDetail _copy(ProjectDetail project, {required String status}) =>
    ProjectDetail(
      id: project.id,
      externalId: project.externalId,
      name: project.name,
      description: project.description,
      customerExternalId: project.customerExternalId,
      customerName: project.customerName,
      sellerExternalId: project.sellerExternalId,
      sellerName: project.sellerName,
      status: status,
      estimatedAmount: project.estimatedAmount,
      startDateUtc: project.startDateUtc,
      expectedCloseDateUtc: project.expectedCloseDateUtc,
      progressPercentage: project.progressPercentage,
      actualCloseDateUtc: project.actualCloseDateUtc,
      address: project.address,
      latitude: project.latitude,
      longitude: project.longitude,
      createdAtUtc: project.createdAtUtc,
    );

const _seller = UserReference(
  id: 7,
  externalId: 'seller-test-id',
  name: 'Vendedor de prueba',
);
