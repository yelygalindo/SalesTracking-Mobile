import 'dart:async';

import '../repositories/workday_repository.dart';
import 'network_status_service.dart';

class ConnectivitySyncCoordinator {
  ConnectivitySyncCoordinator(this._network, this._workdays, {this.onSynced});

  final NetworkStatusService _network;
  final WorkdayRepository _workdays;
  final Future<void> Function()? onSynced;

  StreamSubscription<bool>? _subscription;
  bool _syncing = false;
  bool _disposed = false;

  void start() {
    if (_disposed) return;
    _subscription ??= _network.changes.listen((connected) {
      if (connected) unawaited(_synchronize());
    });
  }

  Future<void> _synchronize() async {
    if (_syncing || _disposed) return;
    _syncing = true;
    try {
      await _workdays.syncPending();
      if (!_disposed) await onSynced?.call();
    } catch (_) {
      // Operations remain durable and will be retried on the next reconnect.
    } finally {
      _syncing = false;
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _subscription?.cancel();
    _subscription = null;
  }
}
