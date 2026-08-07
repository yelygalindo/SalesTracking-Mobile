import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/visit/current_visit.dart';
import '../../data/repositories/visit_repository.dart';
import '../../data/services/api_exception.dart';
import '../../data/services/location_service.dart';

enum VisitCheckOutStatus { initial, loading, ready, saving }

class VisitCheckOutViewModel extends ChangeNotifier {
  VisitCheckOutViewModel(
    this._repository,
    this._locationService, {
    String Function()? requestId,
    DateTime Function()? now,
  }) : _requestId = requestId ?? const Uuid().v4,
       _now = now ?? DateTime.now;

  final VisitRepository _repository;
  final LocationService _locationService;
  final String Function() _requestId;
  final DateTime Function() _now;

  VisitCheckOutStatus _status = VisitCheckOutStatus.initial;
  CurrentVisit? _current;
  String? _errorMessage;

  VisitCheckOutStatus get status => _status;
  CurrentVisit? get current => _current;
  String? get errorMessage => _errorMessage;
  bool get isBusy =>
      _status == VisitCheckOutStatus.loading ||
      _status == VisitCheckOutStatus.saving;

  Future<void> initialize() async {
    _status = VisitCheckOutStatus.loading;
    notifyListeners();
    try {
      _current = await _repository.getCurrent();
      if (_current == null) _errorMessage = 'No hay una visita en curso.';
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No pudimos consultar la visita en curso.';
    }
    _status = VisitCheckOutStatus.ready;
    notifyListeners();
  }

  Future<bool> checkOut({required String result, String? note}) async {
    final visit = _current;
    if (visit == null) {
      _errorMessage = 'No hay una visita en curso.';
      notifyListeners();
      return false;
    }
    if (result.trim().isEmpty) {
      _errorMessage = 'Registra el resultado de la visita.';
      notifyListeners();
      return false;
    }
    _status = VisitCheckOutStatus.saving;
    _errorMessage = null;
    notifyListeners();
    try {
      final occurredAt = _now().toUtc();
      final location = await _locationService.captureCurrent();
      await _repository.checkOut(
        visit: visit,
        checkOutAtUtc: occurredAt,
        location: location,
        clientRequestId: _requestId(),
        note: note?.trim().isEmpty == true ? null : note?.trim(),
        result: result.trim(),
      );
      _current = null;
      _status = VisitCheckOutStatus.ready;
      notifyListeners();
      return true;
    } on LocationFailure catch (error) {
      _errorMessage = error.message;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No pudimos finalizar la visita.';
    }
    _status = VisitCheckOutStatus.ready;
    notifyListeners();
    return false;
  }
}
