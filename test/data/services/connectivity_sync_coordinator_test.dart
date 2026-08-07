import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/common/location_sample.dart';
import 'package:urbantrack/data/models/workday/current_workday_response.dart';
import 'package:urbantrack/data/models/workday/workday.dart';
import 'package:urbantrack/data/repositories/workday_repository.dart';
import 'package:urbantrack/data/services/connectivity_sync_coordinator.dart';
import 'package:urbantrack/data/services/network_status_service.dart';

void main() {
  test('syncs automatically when connectivity returns', () async {
    final network = _ControlledNetworkStatusService();
    final repository = _SyncRecordingRepository();
    final refreshed = Completer<void>();
    final coordinator = ConnectivitySyncCoordinator(
      network,
      repository,
      onSynced: () async => refreshed.complete(),
    )..start();

    network.controller.add(true);
    await refreshed.future.timeout(const Duration(seconds: 1));

    expect(repository.syncCalls, 1);
    await coordinator.dispose();
    await network.controller.close();
  });
}

class _ControlledNetworkStatusService implements NetworkStatusService {
  final StreamController<bool> controller = StreamController<bool>();

  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get changes => controller.stream;
}

class _SyncRecordingRepository implements WorkdayRepository {
  int syncCalls = 0;

  @override
  Future<void> syncPending() async => syncCalls += 1;

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<CurrentWorkdayResponse> getCurrent() async =>
      const CurrentWorkdayResponse(hasOpenWorkday: false, workday: null);

  @override
  Future<Workday> start({
    required DateTime startedAtUtc,
    required LocationSample location,
    required String clientRequestId,
    String? note,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Workday> close({
    required String externalId,
    required DateTime endedAtUtc,
    required LocationSample location,
    required String clientRequestId,
  }) {
    throw UnimplementedError();
  }
}
