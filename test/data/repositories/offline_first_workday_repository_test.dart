import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/common/location_sample.dart';
import 'package:urbantrack/data/models/workday/current_workday_response.dart';
import 'package:urbantrack/data/models/workday/pending_workday_operation.dart';
import 'package:urbantrack/data/models/workday/workday.dart';
import 'package:urbantrack/data/repositories/offline_first_workday_repository.dart';
import 'package:urbantrack/data/repositories/workday_local_store.dart';
import 'package:urbantrack/data/repositories/workday_repository.dart';
import 'package:urbantrack/data/services/api_exception.dart';
import 'package:urbantrack/data/services/network_status_service.dart';

void main() {
  test('queues offline start and close, then syncs them in order', () async {
    final remote = _RecordingRemoteRepository();
    final local = _MemoryWorkdayLocalStore();
    final network = _MutableNetworkStatusService(false);
    final createdTimes = [
      DateTime.utc(2026, 8, 7, 15, 10, 1),
      DateTime.utc(2026, 8, 7, 22, 0, 1),
    ];
    final repository = OfflineFirstWorkdayRepository(
      remote,
      local,
      network,
      now: () => createdTimes.removeAt(0),
    );

    final started = await repository.start(
      startedAtUtc: DateTime.utc(2026, 8, 7, 15, 10),
      location: _startLocation,
      clientRequestId: 'request-start',
      note: 'Inicio offline',
    );
    final closed = await repository.close(
      externalId: started.externalId!,
      endedAtUtc: DateTime.utc(2026, 8, 7, 22),
      location: _endLocation,
      clientRequestId: 'request-close',
    );

    expect(started.externalId, 'local:request-start');
    expect(closed.isOpen, isFalse);
    expect(await repository.pendingCount(), 2);
    expect(local.operations.last.dependsOnRequestId, 'request-start');

    network.connected = true;
    await repository.syncPending();

    expect(remote.calls, [
      'start:request-start',
      'close:server-workday-1:request-close',
    ]);
    expect(await repository.pendingCount(), 0);
    expect(
      await local.serverIdForLocalId('local:request-start'),
      'server-workday-1',
    );
  });

  test(
    'queues an ambiguous transient start failure with the same id',
    () async {
      final remote = _RecordingRemoteRepository(
        startError: const ApiException(message: 'Sin conexión.'),
      );
      final local = _MemoryWorkdayLocalStore();
      final repository = OfflineFirstWorkdayRepository(
        remote,
        local,
        _MutableNetworkStatusService(true),
        now: () => DateTime.utc(2026, 8, 7, 15, 10, 1),
      );

      final workday = await repository.start(
        startedAtUtc: DateTime.utc(2026, 8, 7, 15, 10),
        location: _startLocation,
        clientRequestId: 'stable-request-id',
      );

      expect(workday.externalId, 'local:stable-request-id');
      expect(local.operations.single.requestId, 'stable-request-id');
    },
  );

  test('does not queue a non-transient validation error', () async {
    final remote = _RecordingRemoteRepository(
      startError: const ApiException(
        statusCode: 400,
        message: 'Datos inválidos.',
      ),
    );
    final local = _MemoryWorkdayLocalStore();
    final repository = OfflineFirstWorkdayRepository(
      remote,
      local,
      _MutableNetworkStatusService(true),
    );

    expect(
      () => repository.start(
        startedAtUtc: DateTime.utc(2026, 8, 7, 15, 10),
        location: _startLocation,
        clientRequestId: 'invalid-request',
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          400,
        ),
      ),
    );
    expect(await repository.pendingCount(), 0);
  });
}

const _startLocation = LocationSample(
  latitude: -12.0464,
  longitude: -77.0428,
  accuracyMeters: 7,
);
const _endLocation = LocationSample(
  latitude: -12.05,
  longitude: -77.04,
  accuracyMeters: 5,
);

class _MutableNetworkStatusService implements NetworkStatusService {
  _MutableNetworkStatusService(this.connected);

  bool connected;

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get changes => const Stream.empty();
}

class _RecordingRemoteRepository implements WorkdayRepository {
  _RecordingRemoteRepository({this.startError});

  final ApiException? startError;
  final List<String> calls = [];

  @override
  Future<CurrentWorkdayResponse> getCurrent() async =>
      const CurrentWorkdayResponse(hasOpenWorkday: false, workday: null);

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<void> syncPending() async {}

  @override
  Future<Workday> start({
    required DateTime startedAtUtc,
    required LocationSample location,
    required String clientRequestId,
    String? note,
  }) async {
    calls.add('start:$clientRequestId');
    final error = startError;
    if (error != null) throw error;
    return Workday(
      externalId: 'server-workday-1',
      status: 'open',
      startedAtUtc: startedAtUtc,
      startedReceivedAtUtc: startedAtUtc.add(const Duration(seconds: 2)),
      startLatitude: location.latitude,
      startLongitude: location.longitude,
      note: note,
    );
  }

  @override
  Future<Workday> close({
    required String externalId,
    required DateTime endedAtUtc,
    required LocationSample location,
    required String clientRequestId,
  }) async {
    calls.add('close:$externalId:$clientRequestId');
    return Workday(
      externalId: externalId,
      status: 'closed',
      startedAtUtc: DateTime.utc(2026, 8, 7, 15, 10),
      startedReceivedAtUtc: DateTime.utc(2026, 8, 7, 15, 10, 2),
      startLatitude: _startLocation.latitude,
      startLongitude: _startLocation.longitude,
      endedAtUtc: endedAtUtc,
      endedReceivedAtUtc: endedAtUtc.add(const Duration(seconds: 2)),
      endLatitude: location.latitude,
      endLongitude: location.longitude,
    );
  }
}

class _MemoryWorkdayLocalStore implements WorkdayLocalStore {
  Workday? current;
  final List<PendingWorkdayOperation> operations = [];
  final Map<String, String> mappings = {};
  final Map<String, String> failures = {};

  @override
  Future<void> enqueue(
    PendingWorkdayOperation operation, {
    required Workday current,
  }) async {
    if (!operations.any((item) => item.requestId == operation.requestId)) {
      operations.add(operation);
    }
    this.current = current;
  }

  @override
  Future<void> markSynced(
    String requestId, {
    String? localWorkdayId,
    String? serverWorkdayId,
  }) async {
    if (localWorkdayId != null && serverWorkdayId != null) {
      mappings[localWorkdayId] = serverWorkdayId;
    }
    operations.removeWhere((operation) => operation.requestId == requestId);
  }

  @override
  Future<int> pendingCount() async => operations.length;

  @override
  Future<Workday?> readCurrent() async => current;

  @override
  Future<List<PendingWorkdayOperation>> readPending() async =>
      List.unmodifiable(operations);

  @override
  Future<void> recordFailure(String requestId, String message) async {
    failures[requestId] = message;
  }

  @override
  Future<String?> serverIdForLocalId(String localWorkdayId) async =>
      mappings[localWorkdayId];

  @override
  Future<void> writeCurrent(Workday? workday) async => current = workday;
}
