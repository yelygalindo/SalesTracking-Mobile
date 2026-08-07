import '../models/auth/auth_session.dart';
import '../models/customer/customer_page.dart';
import '../models/customer/customer_status.dart';
import '../services/api_exception.dart';
import '../services/customer_service.dart';
import 'auth_repository.dart';
import 'customer_repository.dart';

class RemoteCustomerRepository implements CustomerRepository {
  const RemoteCustomerRepository(this._service, this._authRepository);

  final CustomerService _service;
  final AuthRepository _authRepository;

  @override
  Future<CustomerPage> getCustomers({
    String? status,
    String? externalUserId,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final session = await _session();
    return _service.getCustomers(
      session.accessToken,
      status: status,
      externalUserId: externalUserId,
      search: search,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<List<CustomerStatus>> getStatuses() async {
    final session = await _session();
    return _service.getStatuses(session.accessToken);
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
