import '../models/auth/auth_session.dart';
import '../models/project/project_detail.dart';
import '../models/project/project_input.dart';
import '../models/project/project_note.dart';
import '../models/project/project_page.dart';
import '../models/project/project_reminder.dart';
import '../models/project/project_status.dart';
import '../models/project/project_timeline_page.dart';
import '../models/common/resource_creation_result.dart';
import '../services/api_exception.dart';
import '../services/project_service.dart';
import 'auth_repository.dart';
import 'project_repository.dart';

class RemoteProjectRepository implements ProjectRepository {
  const RemoteProjectRepository(this._service, this._authRepository);

  final ProjectService _service;
  final AuthRepository _authRepository;

  @override
  Future<ProjectPage> getProjects({
    String? status,
    String? customerId,
    String? sellerId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final session = await _session();
    return _service.getProjects(
      session.accessToken,
      status: status,
      customerId: customerId,
      sellerId: sellerId,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<ProjectDetail> getProject(String externalId) async {
    final session = await _session();
    return _service.getProject(session.accessToken, externalId);
  }

  @override
  Future<List<ProjectStatus>> getStatuses() async {
    final session = await _session();
    return _service.getStatuses(session.accessToken);
  }

  @override
  Future<List<ProjectNote>> getNotes(String projectExternalId) async {
    final session = await _session();
    return _service.getNotes(session.accessToken, projectExternalId);
  }

  @override
  Future<ResourceCreationResult> addNote(
    String projectExternalId, {
    required String content,
    required String clientRequestId,
    required DateTime occurredAtUtc,
  }) async {
    final session = await _session();
    return _service.addNote(
      session.accessToken,
      projectExternalId,
      content: content,
      clientRequestId: clientRequestId,
      occurredAtUtc: occurredAtUtc,
    );
  }

  @override
  Future<List<ProjectReminder>> getReminders(
    String projectExternalId, {
    bool? completed,
  }) async {
    final session = await _session();
    return _service.getReminders(
      session.accessToken,
      projectExternalId,
      completed: completed,
    );
  }

  @override
  Future<ResourceCreationResult> addReminder(
    String projectExternalId, {
    required String text,
    required DateTime reminderAtUtc,
    String? assignedToId,
  }) async {
    final session = await _session();
    final requestedAssignee = assignedToId?.trim();
    final currentUserExternalId = session.user.externalId?.trim();
    return _service.addReminder(
      session.accessToken,
      projectExternalId,
      text: text,
      reminderAtUtc: reminderAtUtc,
      assignedToId: requestedAssignee?.isNotEmpty == true
          ? requestedAssignee
          : currentUserExternalId,
    );
  }

  @override
  Future<void> completeReminder(
    String projectExternalId,
    String reminderExternalId,
  ) async {
    final session = await _session();
    await _service.completeReminder(
      session.accessToken,
      projectExternalId,
      reminderExternalId,
    );
  }

  @override
  Future<ProjectTimelinePage> getTimeline(
    String projectExternalId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final session = await _session();
    return _service.getTimeline(
      session.accessToken,
      projectExternalId,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<ProjectDetail> createProject(
    ProjectInput input,
    String clientRequestId,
  ) async {
    final session = await _session();
    return _service.createProject(session.accessToken, input, clientRequestId);
  }

  @override
  Future<void> updateProject(String externalId, ProjectInput input) async {
    final session = await _session();
    await _service.updateProject(session.accessToken, externalId, input);
  }

  @override
  Future<void> changeStatus(String externalId, int statusId) async {
    final session = await _session();
    await _service.changeStatus(session.accessToken, externalId, statusId);
  }

  Future<AuthSession> _session() async {
    final session = await _authRepository.restoreSession();
    if (session == null) {
      throw const ApiException(
        statusCode: 401,
        message: 'Tu sesión expiró. Inicia sesión nuevamente.',
      );
    }
    return session;
  }
}
