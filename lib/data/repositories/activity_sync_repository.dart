import '../models/activity/pending_activity_operation.dart';
import '../models/sync/sync_queue_entry.dart';
import '../services/api_exception.dart';
import 'activity_local_store.dart';
import 'customer_local_store.dart';
import 'customer_repository.dart';
import 'project_repository.dart';
import 'sync_repository.dart';

class ActivitySyncRepository implements SyncRepository {
  const ActivitySyncRepository(
    this._local,
    this._customers,
    this._projects,
    this._customerLocalStore,
  );

  final ActivityLocalStore _local;
  final CustomerRepository _customers;
  final ProjectRepository _projects;
  final CustomerLocalStore _customerLocalStore;

  @override
  Future<List<SyncQueueEntry>> getPending() async {
    final operations = await _local.readPending();
    return operations.map(_toEntry).toList(growable: false);
  }

  @override
  Future<void> synchronize() async {
    final operations = await _local.readPending();
    for (final operation in operations) {
      try {
        await _dispatch(operation);
        await _local.markSynced(operation.requestId);
      } on ApiException catch (error) {
        await _local.recordFailure(operation.requestId, error.message);
        rethrow;
      } catch (error) {
        await _local.recordFailure(operation.requestId, error.toString());
        rethrow;
      }
    }
  }

  Future<void> _dispatch(PendingActivityOperation operation) async {
    final resourceId = await _resolveResourceId(operation);
    switch ((operation.resourceType, operation.type)) {
      case (ActivityResourceType.customer, PendingActivityOperationType.note):
        await _customers.addNote(
          resourceId,
          operation.text ?? '',
          operation.requestId,
        );
      case (
        ActivityResourceType.customer,
        PendingActivityOperationType.reminder,
      ):
        await _customers.addReminder(
          resourceId,
          text: operation.text ?? '',
          reminderAtUtc: operation.eventAtUtc,
          clientRequestId: operation.requestId,
          assignedToId: operation.assignedToId,
        );
      case (
        ActivityResourceType.customer,
        PendingActivityOperationType.completeReminder,
      ):
        await _customers.completeReminder(
          resourceId,
          _requiredReminderId(operation),
          operation.requestId,
        );
      case (ActivityResourceType.project, PendingActivityOperationType.note):
        await _projects.addNote(
          resourceId,
          content: operation.text ?? '',
          clientRequestId: operation.requestId,
          occurredAtUtc: operation.eventAtUtc,
        );
      case (
        ActivityResourceType.project,
        PendingActivityOperationType.reminder,
      ):
        await _projects.addReminder(
          resourceId,
          text: operation.text ?? '',
          reminderAtUtc: operation.eventAtUtc,
          clientRequestId: operation.requestId,
          assignedToId: operation.assignedToId,
        );
      case (
        ActivityResourceType.project,
        PendingActivityOperationType.completeReminder,
      ):
        await _projects.completeReminder(
          resourceId,
          _requiredReminderId(operation),
          operation.requestId,
        );
    }
  }

  Future<String> _resolveResourceId(PendingActivityOperation operation) async {
    final resourceId = operation.resourceExternalId;
    if (operation.resourceType != ActivityResourceType.customer ||
        !resourceId.startsWith('local:')) {
      return resourceId;
    }
    final resolved = await _customerLocalStore.serverIdForLocalId(resourceId);
    if (resolved == null || resolved.isEmpty) {
      throw const ApiException(
        message: 'El cliente debe sincronizarse antes de su actividad.',
      );
    }
    return resolved;
  }

  String _requiredReminderId(PendingActivityOperation operation) {
    final value = operation.reminderExternalId?.trim();
    if (value == null || value.isEmpty || value.startsWith('local:')) {
      throw const ApiException(
        message: 'El recordatorio debe sincronizarse antes de completarlo.',
      );
    }
    return value;
  }

  SyncQueueEntry _toEntry(PendingActivityOperation operation) {
    final type = switch (operation.resourceType) {
      ActivityResourceType.customer => switch (operation.type) {
        PendingActivityOperationType.note => SyncQueueEntryType.customerNote,
        PendingActivityOperationType.reminder ||
        PendingActivityOperationType.completeReminder =>
          SyncQueueEntryType.customerReminder,
      },
      ActivityResourceType.project => switch (operation.type) {
        PendingActivityOperationType.note => SyncQueueEntryType.projectNote,
        PendingActivityOperationType.reminder ||
        PendingActivityOperationType.completeReminder =>
          SyncQueueEntryType.projectReminder,
      },
    };
    return SyncQueueEntry(
      id: operation.requestId,
      type: type,
      occurredAtUtc: operation.eventAtUtc,
      createdAtUtc: operation.createdAtUtc,
      dependsOnId: operation.resourceExternalId.startsWith('local:')
          ? operation.resourceExternalId
          : null,
      attemptCount: operation.attemptCount,
      lastError: operation.lastError,
    );
  }
}
