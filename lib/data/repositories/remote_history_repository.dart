import '../models/auth/auth_session.dart';
import '../models/history/project_visit.dart';
import '../models/history/seller_timeline_page.dart';
import '../services/api_exception.dart';
import '../services/history_service.dart';
import 'auth_repository.dart';
import 'history_repository.dart';

class RemoteHistoryRepository implements HistoryRepository {
  const RemoteHistoryRepository(this._service, this._authRepository);

  final HistoryService _service;
  final AuthRepository _authRepository;

  @override
  Future<SellerTimelinePage> getMyTimeline({
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 30,
  }) async {
    final session = await _session();
    final sellerExternalId = session.user.externalId?.trim();
    if (sellerExternalId == null || sellerExternalId.isEmpty) {
      throw const ApiException(
        message: 'Tu usuario no tiene un identificador de vendedor.',
      );
    }
    return _service.getSellerTimeline(
      session.accessToken,
      sellerExternalId,
      from: from,
      to: to,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<List<ProjectVisit>> getProjectVisits(
    String projectExternalId, {
    String? sellerExternalId,
    DateTime? from,
    DateTime? to,
  }) async {
    final session = await _session();
    return _service.getProjectVisits(
      session.accessToken,
      projectExternalId,
      sellerExternalId: sellerExternalId,
      from: from,
      to: to,
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
