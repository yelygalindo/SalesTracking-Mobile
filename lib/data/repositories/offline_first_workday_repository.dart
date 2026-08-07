import 'dart:async';

import '../models/common/location_sample.dart';
import '../models/workday/current_workday_response.dart';
import '../models/workday/pending_workday_operation.dart';
import '../models/workday/workday.dart';
import '../services/api_exception.dart';
import '../services/network_status_service.dart';
import 'workday_local_store.dart';
import 'workday_repository.dart';

class OfflineFirstWorkdayRepository implements WorkdayRepository {
  OfflineFirstWorkdayRepository(
    this._remote,
    this._local,
    this._network, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final WorkdayRepository _remote;
  final WorkdayLocalStore _local;
  final NetworkStatusService _network;
  final DateTime Function() _now;

  Future<void>? _activeSync;

  @override
  Future<int> pendingCount() => _local.pendingCount();

  @override
  Future<CurrentWorkdayResponse> getCurrent() async {
    if (!await _network.isConnected) return _cachedResponse();

    try {
      await syncPending();
      final response = await _remote.getCurrent();
      await _local.writeCurrent(
        response.hasOpenWorkday ? response.workday : null,
      );
      return response;
    } on ApiException catch (error) {
      if (!_isTransient(error)) rethrow;
      return _cachedResponse();
    }
  }

  @override
  Future<Workday> start({
    required DateTime startedAtUtc,
    required LocationSample location,
    required String clientRequestId,
    String? note,
  }) async {
    if (await _network.isConnected) {
      try {
        final workday = await _remote.start(
          startedAtUtc: startedAtUtc,
          location: location,
          clientRequestId: clientRequestId,
          note: note,
        );
        await _local.writeCurrent(workday);
        return workday;
      } on ApiException catch (error) {
        if (!_isTransient(error)) rethrow;
      }
    }

    final localId = 'local:$clientRequestId';
    final localWorkday = Workday(
      externalId: localId,
      status: 'pending_sync',
      startedAtUtc: startedAtUtc.toUtc(),
      startedReceivedAtUtc: startedAtUtc.toUtc(),
      startLatitude: location.latitude,
      startLongitude: location.longitude,
      note: note,
    );
    await _local.enqueue(
      PendingWorkdayOperation(
        requestId: clientRequestId,
        localWorkdayId: localId,
        type: PendingWorkdayOperationType.start,
        occurredAtUtc: startedAtUtc.toUtc(),
        location: location,
        note: note,
        createdAtUtc: _now().toUtc(),
      ),
      current: localWorkday,
    );
    return localWorkday;
  }

  @override
  Future<Workday> close({
    required String externalId,
    required DateTime endedAtUtc,
    required LocationSample location,
    required String clientRequestId,
  }) async {
    final cached = await _local.readCurrent();
    if (cached == null) {
      throw const ApiException(
        message: 'No hay una jornada local válida para cerrar.',
      );
    }

    if (!externalId.startsWith('local:') && await _network.isConnected) {
      try {
        final workday = await _remote.close(
          externalId: externalId,
          endedAtUtc: endedAtUtc,
          location: location,
          clientRequestId: clientRequestId,
        );
        await _local.writeCurrent(workday);
        return workday;
      } on ApiException catch (error) {
        if (!_isTransient(error)) rethrow;
      }
    }

    final localWorkday = _closedProjection(cached, endedAtUtc, location);
    final isLocalId = externalId.startsWith('local:');
    await _local.enqueue(
      PendingWorkdayOperation(
        requestId: clientRequestId,
        localWorkdayId: externalId,
        type: PendingWorkdayOperationType.close,
        occurredAtUtc: endedAtUtc.toUtc(),
        location: location,
        serverWorkdayId: isLocalId ? null : externalId,
        dependsOnRequestId: isLocalId
            ? externalId.substring('local:'.length)
            : null,
        createdAtUtc: _now().toUtc(),
      ),
      current: localWorkday,
    );

    if (await _network.isConnected) {
      try {
        await syncPending();
      } on ApiException {
        // The durable queue keeps the close operation for a later retry.
      }
    }
    return localWorkday;
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
          case PendingWorkdayOperationType.start:
            final workday = await _remote.start(
              startedAtUtc: operation.occurredAtUtc,
              location: operation.location,
              clientRequestId: operation.requestId,
              note: operation.note,
            );
            final serverId = workday.externalId;
            if (serverId == null || serverId.isEmpty) {
              throw const ApiException(
                message: 'El servidor no devolvió el ID de la jornada.',
              );
            }
            await _local.markSynced(
              operation.requestId,
              localWorkdayId: operation.localWorkdayId,
              serverWorkdayId: serverId,
            );
          case PendingWorkdayOperationType.close:
            final serverId =
                operation.serverWorkdayId ??
                await _local.serverIdForLocalId(operation.localWorkdayId);
            if (serverId == null || serverId.isEmpty) {
              throw const ApiException(
                message: 'La jornada de inicio aún no se ha sincronizado.',
              );
            }
            await _remote.close(
              externalId: serverId,
              endedAtUtc: operation.occurredAtUtc,
              location: operation.location,
              clientRequestId: operation.requestId,
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

  Future<CurrentWorkdayResponse> _cachedResponse() async {
    final workday = await _local.readCurrent();
    final openWorkday = workday?.isOpen == true ? workday : null;
    return CurrentWorkdayResponse(
      hasOpenWorkday: openWorkday != null,
      workday: openWorkday,
    );
  }

  bool _isTransient(ApiException error) {
    final status = error.statusCode;
    return status == null || status == 408 || status == 429 || status >= 500;
  }

  Workday _closedProjection(
    Workday workday,
    DateTime endedAtUtc,
    LocationSample location,
  ) {
    return Workday(
      externalId: workday.externalId,
      status: 'closed_pending_sync',
      startedAtUtc: workday.startedAtUtc,
      startedReceivedAtUtc: workday.startedReceivedAtUtc,
      startLatitude: workday.startLatitude,
      startLongitude: workday.startLongitude,
      note: workday.note,
      endedAtUtc: endedAtUtc.toUtc(),
      endedReceivedAtUtc: endedAtUtc.toUtc(),
      endLatitude: location.latitude,
      endLongitude: location.longitude,
    );
  }
}
