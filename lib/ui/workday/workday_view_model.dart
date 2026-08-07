import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/common/location_sample.dart';
import '../../data/models/workday/workday.dart';
import '../../data/repositories/workday_repository.dart';
import '../../data/services/api_exception.dart';
import '../../data/services/location_service.dart';

enum WorkdayStatus { initial, loading, ready, starting, locating, closing }

class WorkdayViewModel extends ChangeNotifier {
  WorkdayViewModel(
    this._repository,
    this._locationService, {
    DateTime Function()? now,
    String Function()? requestId,
  }) : _now = now ?? DateTime.now,
       _requestId = requestId ?? const Uuid().v4;

  final WorkdayRepository _repository;
  final LocationService _locationService;
  final DateTime Function() _now;
  final String Function() _requestId;

  WorkdayStatus _status = WorkdayStatus.initial;
  Workday? _workday;
  LocationSample? _closeLocation;
  String? _errorMessage;
  int _pendingCount = 0;

  WorkdayStatus get status => _status;
  Workday? get workday => _workday;
  LocationSample? get closeLocation => _closeLocation;
  String? get errorMessage => _errorMessage;
  int get pendingCount => _pendingCount;
  bool get hasPendingSync => _pendingCount > 0;
  bool get hasOpenWorkday => _workday?.isOpen == true;
  bool get isBusy =>
      _status == WorkdayStatus.loading ||
      _status == WorkdayStatus.starting ||
      _status == WorkdayStatus.locating ||
      _status == WorkdayStatus.closing;

  Future<void> loadCurrent() async {
    _status = WorkdayStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.getCurrent();
      _workday = response.hasOpenWorkday ? response.workday : null;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } on FormatException {
      _errorMessage = 'El servidor devolvió una jornada no válida.';
    } catch (_) {
      _errorMessage = 'No pudimos consultar la jornada actual.';
    }

    await _refreshPendingCount();
    _status = WorkdayStatus.ready;
    notifyListeners();
  }

  Future<bool> startWorkday({String? note}) async {
    _status = WorkdayStatus.starting;
    _errorMessage = null;
    notifyListeners();

    try {
      final location = await _locationService.captureCurrent();
      _workday = await _repository.start(
        startedAtUtc: _now().toUtc(),
        location: location,
        clientRequestId: _requestId(),
        note: note,
      );
      await _refreshPendingCount();
      _status = WorkdayStatus.ready;
      notifyListeners();
      return true;
    } on LocationFailure catch (error) {
      _errorMessage = error.message;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No pudimos iniciar la jornada.';
    }

    await _refreshPendingCount();
    _status = WorkdayStatus.ready;
    notifyListeners();
    return false;
  }

  Future<bool> prepareCloseLocation() async {
    _status = WorkdayStatus.locating;
    _closeLocation = null;
    _errorMessage = null;
    notifyListeners();

    try {
      _closeLocation = await _locationService.captureCurrent();
      _status = WorkdayStatus.ready;
      notifyListeners();
      return true;
    } on LocationFailure catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No pudimos obtener la ubicación de cierre.';
    }

    _status = WorkdayStatus.ready;
    notifyListeners();
    return false;
  }

  Future<bool> closeWorkday() async {
    final current = _workday;
    final externalId = current?.externalId;
    if (current == null || externalId == null) {
      _errorMessage = 'No hay una jornada válida para cerrar.';
      notifyListeners();
      return false;
    }

    var location = _closeLocation;
    if (location == null && !await prepareCloseLocation()) return false;
    location = _closeLocation!;

    _status = WorkdayStatus.closing;
    _errorMessage = null;
    notifyListeners();

    try {
      _workday = await _repository.close(
        externalId: externalId,
        endedAtUtc: _now().toUtc(),
        location: location,
        clientRequestId: _requestId(),
      );
      _closeLocation = null;
      await _refreshPendingCount();
      _status = WorkdayStatus.ready;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No pudimos cerrar la jornada.';
    }

    await _refreshPendingCount();
    _status = WorkdayStatus.ready;
    notifyListeners();
    return false;
  }

  Future<void> _refreshPendingCount() async {
    try {
      _pendingCount = await _repository.pendingCount();
    } catch (_) {
      // A pending-count failure must not block a workday operation.
    }
  }
}
