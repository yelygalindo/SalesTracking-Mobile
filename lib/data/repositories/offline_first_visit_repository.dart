import '../models/common/location_sample.dart';
import '../models/visit/current_visit.dart';
import '../models/visit/pending_visit_operation.dart';
import '../models/visit/visit_target_type.dart';
import '../services/api_exception.dart';
import '../services/network_status_service.dart';
import 'visit_local_store.dart';
import 'visit_repository.dart';

class OfflineFirstVisitRepository implements VisitRepository {
  OfflineFirstVisitRepository(
    this._remote,
    this._local,
    this._network, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final VisitRepository _remote;
  final VisitLocalStore _local;
  final NetworkStatusService _network;
  final DateTime Function() _now;

  Future<void>? _activeSync;

  @override
  Future<int> pendingCount() => _local.pendingCount();

  @override
  Future<CurrentVisit?> getCurrent() async {
    final cached = await _local.readCurrent();
    if (!await _network.isConnected) return cached;
    try {
      await syncPending();
      final remote = await _remote.getCurrent();
      await _local.writeCurrent(remote);
      return remote;
    } on ApiException catch (error) {
      if (!_isTransient(error)) rethrow;
      return cached;
    }
  }

  @override
  Future<CurrentVisit> checkIn({
    required VisitTargetType targetType,
    required String targetExternalId,
    required String targetName,
    required DateTime checkInAtUtc,
    required LocationSample location,
    required String clientRequestId,
    String? note,
  }) async {
    final current = await _local.readCurrent();
    if (current != null) {
      throw ApiException(
        statusCode: 409,
        message: 'Ya tienes una visita en curso en ${current.targetName}.',
      );
    }
    if (await _network.isConnected) {
      try {
        final visit = await _remote.checkIn(
          targetType: targetType,
          targetExternalId: targetExternalId,
          targetName: targetName,
          checkInAtUtc: checkInAtUtc,
          location: location,
          clientRequestId: clientRequestId,
          note: note,
        );
        await _local.writeCurrent(visit);
        return visit;
      } on ApiException catch (error) {
        if (!_isTransient(error)) rethrow;
      }
    }

    final localId = 'local:$clientRequestId';
    final visit = CurrentVisit(
      type: targetType,
      externalId: localId,
      targetExternalId: targetExternalId,
      targetName: targetName,
      checkInAtUtc: checkInAtUtc.toUtc(),
      latitude: location.latitude,
      longitude: location.longitude,
      note: note,
    );
    await _local.enqueue(
      PendingVisitOperation(
        requestId: clientRequestId,
        localVisitId: localId,
        type: PendingVisitOperationType.checkIn,
        targetType: targetType,
        targetExternalId: targetExternalId,
        targetName: targetName,
        occurredAtUtc: checkInAtUtc.toUtc(),
        location: location,
        note: note,
        createdAtUtc: _now().toUtc(),
      ),
      current: visit,
    );
    return visit;
  }

  @override
  Future<void> checkOut({
    required CurrentVisit visit,
    required DateTime checkOutAtUtc,
    required LocationSample location,
    required String clientRequestId,
    String? note,
    String? result,
  }) async {
    final isLocal = visit.externalId.startsWith('local:');
    if (!isLocal && await _network.isConnected) {
      try {
        await _remote.checkOut(
          visit: visit,
          checkOutAtUtc: checkOutAtUtc,
          location: location,
          clientRequestId: clientRequestId,
          note: note,
          result: result,
        );
        await _local.writeCurrent(null);
        return;
      } on ApiException catch (error) {
        if (!_isTransient(error)) rethrow;
      }
    }

    await _local.enqueue(
      PendingVisitOperation(
        requestId: clientRequestId,
        localVisitId: visit.externalId,
        type: PendingVisitOperationType.checkOut,
        targetType: visit.type,
        targetExternalId: visit.targetExternalId,
        targetName: visit.targetName,
        occurredAtUtc: checkOutAtUtc.toUtc(),
        location: location,
        note: note,
        result: result,
        serverVisitId: isLocal ? null : visit.externalId,
        dependsOnRequestId: isLocal
            ? visit.externalId.substring('local:'.length)
            : null,
        createdAtUtc: _now().toUtc(),
      ),
      current: null,
    );
    if (await _network.isConnected) {
      try {
        await syncPending();
      } on ApiException {
        // The durable queue will retry later.
      }
    }
  }

  @override
  Future<void> syncPending() {
    final active = _activeSync;
    if (active != null) return active;
    late final Future<void> current;
    current = _syncPendingInternal().whenComplete(() {
      if (identical(_activeSync, current)) _activeSync = null;
    });
    _activeSync = current;
    return current;
  }

  Future<void> _syncPendingInternal() async {
    if (!await _network.isConnected) return;
    final operations = await _local.readPending();
    for (final operation in operations) {
      try {
        switch (operation.type) {
          case PendingVisitOperationType.checkIn:
            final visit = await _remote.checkIn(
              targetType: operation.targetType,
              targetExternalId: operation.targetExternalId,
              targetName: operation.targetName,
              checkInAtUtc: operation.occurredAtUtc,
              location: operation.location,
              clientRequestId: operation.requestId,
              note: operation.note,
            );
            await _local.markSynced(
              operation.requestId,
              localVisitId: operation.localVisitId,
              serverVisitId: visit.externalId,
            );
          case PendingVisitOperationType.checkOut:
            final serverId =
                operation.serverVisitId ??
                await _local.serverIdForLocalId(operation.localVisitId);
            if (serverId == null || serverId.isEmpty) {
              throw const ApiException(
                message: 'El inicio de la visita aún no se ha sincronizado.',
              );
            }
            await _remote.checkOut(
              visit: CurrentVisit(
                type: operation.targetType,
                externalId: serverId,
                targetExternalId: operation.targetExternalId,
                targetName: operation.targetName,
                checkInAtUtc: operation.occurredAtUtc,
                latitude: operation.location.latitude,
                longitude: operation.location.longitude,
                note: null,
              ),
              checkOutAtUtc: operation.occurredAtUtc,
              location: operation.location,
              clientRequestId: operation.requestId,
              note: operation.note,
              result: operation.result,
            );
            await _local.markSynced(operation.requestId);
        }
      } on ApiException catch (error) {
        await _local.recordFailure(operation.requestId, error.message);
        rethrow;
      } catch (error) {
        await _local.recordFailure(operation.requestId, error.toString());
        rethrow;
      }
    }
  }

  bool _isTransient(ApiException error) {
    final status = error.statusCode;
    return status == null || status == 408 || status == 429 || status >= 500;
  }
}
