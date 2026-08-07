import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/visit/current_visit.dart';
import '../../data/models/visit/visit_target_type.dart';
import '../../data/repositories/visit_repository.dart';
import '../../data/services/api_exception.dart';
import '../../data/services/location_service.dart';

enum VisitCheckInStatus { initial, loading, ready, saving }

class VisitCheckInViewModel extends ChangeNotifier {
  VisitCheckInViewModel(
    this._repository,
    this._locationService, {
    required this.targetType,
    required this.targetExternalId,
    required this.targetName,
    String Function()? requestId,
    DateTime Function()? now,
  }) : _requestId = requestId ?? const Uuid().v4,
       _now = now ?? DateTime.now;

  final VisitRepository _repository;
  final LocationService _locationService;
  final VisitTargetType targetType;
  final String targetExternalId;
  final String targetName;
  final String Function() _requestId;
  final DateTime Function() _now;

  VisitCheckInStatus _status = VisitCheckInStatus.initial;
  CurrentVisit? _current;
  String? _errorMessage;

  VisitCheckInStatus get status => _status;
  CurrentVisit? get current => _current;
  String? get errorMessage => _errorMessage;
  bool get isBusy =>
      _status == VisitCheckInStatus.loading ||
      _status == VisitCheckInStatus.saving;

  Future<void> initialize() async {
    _status = VisitCheckInStatus.loading;
    notifyListeners();
    try {
      _current = await _repository.getCurrent();
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No pudimos comprobar las visitas en curso.';
    }
    _status = VisitCheckInStatus.ready;
    notifyListeners();
  }

  Future<bool> checkIn(String? note) async {
    final current = _current;
    if (current != null) {
      _errorMessage = 'Ya tienes una visita en curso en ${current.targetName}.';
      notifyListeners();
      return false;
    }
    _status = VisitCheckInStatus.saving;
    _errorMessage = null;
    notifyListeners();
    try {
      final occurredAt = _now().toUtc();
      final location = await _locationService.captureCurrent();
      _current = await _repository.checkIn(
        targetType: targetType,
        targetExternalId: targetExternalId,
        targetName: targetName,
        checkInAtUtc: occurredAt,
        location: location,
        clientRequestId: _requestId(),
        note: note?.trim().isEmpty == true ? null : note?.trim(),
      );
      _status = VisitCheckInStatus.ready;
      notifyListeners();
      return true;
    } on LocationFailure catch (error) {
      _errorMessage = error.message;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No pudimos iniciar la visita.';
    }
    _status = VisitCheckInStatus.ready;
    notifyListeners();
    return false;
  }
}
