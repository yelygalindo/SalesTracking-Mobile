import '../models/auth/auth_session.dart';
import '../models/common/location_sample.dart';
import '../models/visit/current_visit.dart';
import '../models/visit/visit_target_type.dart';
import '../services/api_exception.dart';
import '../services/visit_service.dart';
import 'auth_repository.dart';
import 'visit_repository.dart';

class RemoteVisitRepository implements VisitRepository {
  const RemoteVisitRepository(this._service, this._authRepository);

  final VisitService _service;
  final AuthRepository _authRepository;

  @override
  Future<CurrentVisit?> getCurrent() async {
    final session = await _session();
    return _service.getCurrent(session.accessToken);
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
    final session = await _session();
    final result = await _service.checkIn(
      session.accessToken,
      targetType: targetType,
      targetExternalId: targetExternalId,
      checkInAtUtc: checkInAtUtc,
      location: location,
      clientRequestId: clientRequestId,
      note: note,
    );
    final externalId = result.id;
    if (externalId == null || externalId.isEmpty) {
      throw const ApiException(
        message: 'El servidor no devolvió el ID de la visita.',
      );
    }
    return CurrentVisit(
      type: targetType,
      externalId: externalId,
      targetExternalId: targetExternalId,
      targetName: targetName,
      checkInAtUtc: checkInAtUtc.toUtc(),
      latitude: location.latitude,
      longitude: location.longitude,
      note: note,
    );
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
    final session = await _session();
    await _service.checkOut(
      session.accessToken,
      targetType: visit.type,
      targetExternalId: visit.targetExternalId,
      visitExternalId: visit.externalId,
      checkOutAtUtc: checkOutAtUtc,
      location: location,
      clientRequestId: clientRequestId,
      note: note,
      result: result,
    );
  }

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<void> syncPending() async {}

  Future<AuthSession> _session() async {
    final session = await _authRepository.restoreSession();
    if (session == null) {
      throw const ApiException(
        statusCode: 401,
        message: 'Tu sesión expiró. Inicia sesión nuevamente.',
      );
    }
    return session;
  }
}
