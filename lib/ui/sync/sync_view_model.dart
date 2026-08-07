import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/sync/sync_queue_entry.dart';
import '../../data/repositories/sync_repository.dart';
import '../../data/services/api_exception.dart';
import '../../data/services/network_status_service.dart';

enum SyncViewStatus { initial, loading, ready, synchronizing }

class SyncViewModel extends ChangeNotifier {
  SyncViewModel(this._repository, this._network, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final SyncRepository _repository;
  final NetworkStatusService _network;
  final DateTime Function() _now;

  StreamSubscription<bool>? _networkSubscription;
  SyncViewStatus _status = SyncViewStatus.initial;
  List<SyncQueueEntry> _items = const [];
  bool _connected = false;
  String? _errorMessage;
  DateTime? _lastAttemptAt;
  bool _initialized = false;

  SyncViewStatus get status => _status;
  List<SyncQueueEntry> get items => _items;
  bool get connected => _connected;
  String? get errorMessage => _errorMessage;
  DateTime? get lastAttemptAt => _lastAttemptAt;
  bool get isBusy =>
      _status == SyncViewStatus.loading ||
      _status == SyncViewStatus.synchronizing;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      _connected = await _network.isConnected;
    } catch (_) {
      _connected = false;
    }
    _networkSubscription = _network.changes.listen((connected) {
      _connected = connected;
      notifyListeners();
    });
    await load();
  }

  Future<void> load() async {
    _status = SyncViewStatus.loading;
    notifyListeners();
    await _reloadItems();
    _status = SyncViewStatus.ready;
    notifyListeners();
  }

  Future<bool> synchronize() async {
    _lastAttemptAt = _now();
    _errorMessage = null;
    if (!_connected) {
      _errorMessage =
          'Todavía no hay conexión. Los registros permanecen guardados.';
      notifyListeners();
      return false;
    }

    _status = SyncViewStatus.synchronizing;
    notifyListeners();
    var success = false;
    try {
      await _repository.synchronize();
      success = true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No pudimos completar la sincronización.';
    }

    await _reloadItems();
    _status = SyncViewStatus.ready;
    notifyListeners();
    return success;
  }

  Future<void> _reloadItems() async {
    try {
      _items = await _repository.getPending();
    } catch (_) {
      _errorMessage = 'No pudimos consultar los registros pendientes.';
    }
  }

  @override
  void dispose() {
    unawaited(_networkSubscription?.cancel());
    super.dispose();
  }
}
