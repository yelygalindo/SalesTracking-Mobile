import '../models/auth/auth_session.dart';
import '../models/common/location_sample.dart';
import '../models/workday/close_workday_request.dart';
import '../models/workday/current_workday_response.dart';
import '../models/workday/start_workday_request.dart';
import '../models/workday/workday.dart';
import '../services/api_exception.dart';
import '../services/workday_service.dart';
import 'auth_repository.dart';
import 'workday_repository.dart';

class RemoteWorkdayRepository implements WorkdayRepository {
  const RemoteWorkdayRepository(this._service, this._authRepository);

  final WorkdayService _service;
  final AuthRepository _authRepository;

  @override
  Future<CurrentWorkdayResponse> getCurrent() async {
    final session = await _session();
    return _service.getCurrent(session.accessToken);
  }

  @override
  Future<Workday> start({
    required DateTime startedAtUtc,
    required LocationSample location,
    required String clientRequestId,
    String? note,
  }) async {
    final session = await _session();
    return _service.start(
      session.accessToken,
      StartWorkdayRequest(
        startedAtUtc: startedAtUtc,
        latitude: location.latitude,
        longitude: location.longitude,
        note: note,
        clientRequestId: clientRequestId,
      ),
    );
  }

  @override
  Future<Workday> close({
    required String externalId,
    required DateTime endedAtUtc,
    required LocationSample location,
    required String clientRequestId,
  }) async {
    final session = await _session();
    return _service.close(
      session.accessToken,
      externalId,
      CloseWorkdayRequest(
        endedAtUtc: endedAtUtc,
        latitude: location.latitude,
        longitude: location.longitude,
        clientRequestId: clientRequestId,
      ),
    );
  }

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
