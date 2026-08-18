import '../models/activity/pending_activity_operation.dart';
import '../models/project/project_detail.dart';
import '../models/project/project_input.dart';
import '../models/project/project_note.dart';
import '../models/project/project_page.dart';
import '../models/project/project_reminder.dart';
import '../models/project/project_status.dart';
import '../models/project/project_timeline_page.dart';
import '../models/common/resource_creation_result.dart';
import '../services/api_exception.dart';
import '../services/network_status_service.dart';
import 'activity_local_store.dart';
import 'project_local_store.dart';
import 'project_repository.dart';

class OfflineFirstProjectRepository implements ProjectRepository {
  OfflineFirstProjectRepository(
    this._remote,
    this._local,
    this._network, {
    ActivityLocalStore? activityLocalStore,
    DateTime Function()? now,
  }) : _activityLocal = activityLocalStore,
       _now = now ?? DateTime.now;

  final ProjectRepository _remote;
  final ProjectLocalStore _local;
  final NetworkStatusService _network;
  final ActivityLocalStore? _activityLocal;
  final DateTime Function() _now;

  @override
  Future<ProjectPage> getProjects({
    String? status,
    String? customerId,
    String? sellerId,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (await _network.isConnected) {
      try {
        final remotePage = await _remote.getProjects(
          status: status,
          customerId: customerId,
          sellerId: sellerId,
          page: page,
          pageSize: pageSize,
        );
        await _local.cacheProjects(remotePage.projects);
        return remotePage;
      } on ApiException catch (error) {
        if (!_isTransient(error)) rethrow;
      }
    }
    return _local.readProjects(
      status: status,
      customerId: customerId,
      sellerId: sellerId,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<ProjectDetail> getProject(String externalId) async {
    if (await _network.isConnected) {
      try {
        final project = await _remote.getProject(externalId);
        await _local.cacheDetail(project);
        return project;
      } on ApiException catch (error) {
        if (!_isTransient(error)) rethrow;
      }
    }
    final cached = await _local.readDetail(externalId);
    if (cached != null) return cached;
    throw const ApiException(
      message: 'Esta obra todavía no está disponible sin conexión.',
    );
  }

  @override
  Future<List<ProjectStatus>> getStatuses() async {
    if (await _network.isConnected) {
      try {
        final statuses = await _remote.getStatuses();
        await _local.cacheStatuses(statuses);
        return statuses;
      } on ApiException catch (error) {
        if (!_isTransient(error)) rethrow;
      }
    }
    return _local.readStatuses();
  }

  @override
  Future<List<ProjectNote>> getNotes(String projectExternalId) async {
    final activityLocal = _activityLocal;
    if (activityLocal == null) {
      await _requireConnection(
        'Necesitas conexión para consultar las notas de esta obra.',
      );
      return _remote.getNotes(projectExternalId);
    }
    List<ProjectNote> notes;
    if (await _network.isConnected) {
      try {
        notes = await _remote.getNotes(projectExternalId);
        await activityLocal.cacheProjectNotes(projectExternalId, notes);
      } on ApiException catch (error) {
        if (!_isTransient(error)) rethrow;
        notes = await activityLocal.readProjectNotes(projectExternalId);
      }
    } else {
      notes = await activityLocal.readProjectNotes(projectExternalId);
    }
    return _mergePendingNotes(projectExternalId, notes);
  }

  @override
  Future<ResourceCreationResult> addNote(
    String projectExternalId, {
    required String content,
    required String clientRequestId,
    required DateTime occurredAtUtc,
  }) async {
    final activityLocal = _activityLocal;
    if (activityLocal == null) {
      await _requireConnection(
        'Necesitas conexión para agregar una nota a esta obra.',
      );
      return _remote.addNote(
        projectExternalId,
        content: content,
        clientRequestId: clientRequestId,
        occurredAtUtc: occurredAtUtc,
      );
    }
    if (await _network.isConnected) {
      try {
        return await _remote.addNote(
          projectExternalId,
          content: content,
          clientRequestId: clientRequestId,
          occurredAtUtc: occurredAtUtc,
        );
      } on ApiException catch (error) {
        if (!_isTransient(error)) rethrow;
      }
    }
    await activityLocal.enqueue(
      PendingActivityOperation(
        requestId: clientRequestId,
        resourceType: ActivityResourceType.project,
        resourceExternalId: projectExternalId,
        type: PendingActivityOperationType.note,
        text: content.trim(),
        eventAtUtc: occurredAtUtc.toUtc(),
        createdAtUtc: _now().toUtc(),
      ),
    );
    return ResourceCreationResult(
      id: 'local:$clientRequestId',
      message: 'Nota guardada. Se sincronizará al recuperar conexión.',
    );
  }

  @override
  Future<List<ProjectReminder>> getReminders(
    String projectExternalId, {
    bool? completed,
  }) async {
    final activityLocal = _activityLocal;
    if (activityLocal == null) {
      await _requireConnection(
        'Necesitas conexión para consultar los recordatorios de esta obra.',
      );
      return _remote.getReminders(projectExternalId, completed: completed);
    }
    List<ProjectReminder> reminders;
    if (await _network.isConnected) {
      try {
        reminders = await _remote.getReminders(projectExternalId);
        await activityLocal.cacheProjectReminders(projectExternalId, reminders);
      } on ApiException catch (error) {
        if (!_isTransient(error)) rethrow;
        reminders = await activityLocal.readProjectReminders(projectExternalId);
      }
    } else {
      reminders = await activityLocal.readProjectReminders(projectExternalId);
    }
    final merged = await _mergePendingReminders(projectExternalId, reminders);
    return completed == null
        ? merged
        : merged
              .where((reminder) => reminder.completed == completed)
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
    final activityLocal = _activityLocal;
    if (activityLocal == null) {
      await _requireConnection(
        'Necesitas conexión para agregar un recordatorio a esta obra.',
      );
      return _remote.addReminder(
        projectExternalId,
        text: text,
        reminderAtUtc: reminderAtUtc,
        clientRequestId: clientRequestId,
        assignedToId: assignedToId,
      );
    }
    if (await _network.isConnected) {
      try {
        return await _remote.addReminder(
          projectExternalId,
          text: text,
          reminderAtUtc: reminderAtUtc,
          clientRequestId: clientRequestId,
          assignedToId: assignedToId,
        );
      } on ApiException catch (error) {
        if (!_isTransient(error)) rethrow;
      }
    }
    await activityLocal.enqueue(
      PendingActivityOperation(
        requestId: clientRequestId,
        resourceType: ActivityResourceType.project,
        resourceExternalId: projectExternalId,
        type: PendingActivityOperationType.reminder,
        text: text.trim(),
        assignedToId: assignedToId,
        eventAtUtc: reminderAtUtc.toUtc(),
        createdAtUtc: _now().toUtc(),
      ),
    );
    return ResourceCreationResult(
      id: 'local:$clientRequestId',
      message: 'Recordatorio guardado. Se sincronizará al recuperar conexión.',
    );
  }

  @override
  Future<void> completeReminder(
    String projectExternalId,
    String reminderExternalId,
    String clientRequestId,
  ) async {
    final activityLocal = _activityLocal;
    if (activityLocal == null) {
      await _requireConnection(
        'Necesitas conexión para completar un recordatorio de esta obra.',
      );
      await _remote.completeReminder(
        projectExternalId,
        reminderExternalId,
        clientRequestId,
      );
      return;
    }
    if (reminderExternalId.startsWith('local:')) {
      throw const ApiException(
        message: 'Sincroniza el recordatorio antes de completarlo.',
      );
    }
    if (await _network.isConnected) {
      try {
        await _remote.completeReminder(
          projectExternalId,
          reminderExternalId,
          clientRequestId,
        );
        return;
      } on ApiException catch (error) {
        if (!_isTransient(error)) rethrow;
      }
    }
    await activityLocal.enqueue(
      PendingActivityOperation(
        requestId: clientRequestId,
        resourceType: ActivityResourceType.project,
        resourceExternalId: projectExternalId,
        type: PendingActivityOperationType.completeReminder,
        reminderExternalId: reminderExternalId,
        eventAtUtc: _now().toUtc(),
        createdAtUtc: _now().toUtc(),
      ),
    );
  }

  @override
  Future<ProjectTimelinePage> getTimeline(
    String projectExternalId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    await _requireConnection(
      'Necesitas conexión para consultar el historial de esta obra.',
    );
    return _remote.getTimeline(
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
    await _requireConnection('Necesitas conexión para registrar una obra.');
    final project = await _remote.createProject(input, clientRequestId);
    await _local.cacheDetail(project);
    return project;
  }

  @override
  Future<void> updateProject(String externalId, ProjectInput input) async {
    await _requireConnection('Necesitas conexión para editar esta obra.');
    await _remote.updateProject(externalId, input);
    final refreshed = await _remote.getProject(externalId);
    await _local.cacheDetail(refreshed);
  }

  @override
  Future<void> changeStatus(String externalId, int statusId) async {
    await _requireConnection(
      'Necesitas conexión para cambiar el estado de la obra.',
    );
    await _remote.changeStatus(externalId, statusId);
    final refreshed = await _remote.getProject(externalId);
    await _local.cacheDetail(refreshed);
  }

  Future<void> _requireConnection(String message) async {
    if (!await _network.isConnected) throw ApiException(message: message);
  }

  bool _isTransient(ApiException error) {
    final status = error.statusCode;
    return status == null || status == 408 || status == 429 || status >= 500;
  }

  Future<List<ProjectNote>> _mergePendingNotes(
    String projectExternalId,
    List<ProjectNote> notes,
  ) async {
    final operations = await _activityLocal!.readPending(
      resourceType: ActivityResourceType.project,
      resourceExternalId: projectExternalId,
    );
    final pending = operations
        .where(
          (operation) => operation.type == PendingActivityOperationType.note,
        )
        .map(
          (operation) => ProjectNote(
            id: 0,
            externalId: 'local:${operation.requestId}',
            content: operation.text ?? '',
            createdBy: null,
            createdAtUtc: operation.eventAtUtc,
            occurredAtUtc: operation.eventAtUtc,
            receivedAtUtc: operation.createdAtUtc,
            updatedBy: null,
            updatedAtUtc: null,
          ),
        );
    return [...notes, ...pending];
  }

  Future<List<ProjectReminder>> _mergePendingReminders(
    String projectExternalId,
    List<ProjectReminder> reminders,
  ) async {
    final operations = await _activityLocal!.readPending(
      resourceType: ActivityResourceType.project,
      resourceExternalId: projectExternalId,
    );
    final completed = operations
        .where(
          (operation) =>
              operation.type == PendingActivityOperationType.completeReminder,
        )
        .map((operation) => operation.reminderExternalId)
        .whereType<String>()
        .toSet();
    final pending = operations
        .where(
          (operation) =>
              operation.type == PendingActivityOperationType.reminder,
        )
        .map(
          (operation) => ProjectReminder(
            id: 0,
            externalId: 'local:${operation.requestId}',
            text: operation.text ?? '',
            reminderAtUtc: operation.eventAtUtc,
            assignedTo: null,
            completed: false,
          ),
        );
    return [
      ...reminders.where(
        (reminder) => !completed.contains(reminder.externalId),
      ),
      ...pending,
    ];
  }
}
