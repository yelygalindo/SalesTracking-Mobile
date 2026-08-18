import '../models/auth/auth_session.dart';
import '../models/common/resource_creation_result.dart';
import '../models/customer/customer_detail.dart';
import '../models/customer/customer_input.dart';
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

  @override
  Future<CustomerDetail> getCustomer(String externalId) async {
    final session = await _session();
    return _service.getCustomer(session.accessToken, externalId);
  }

  @override
  Future<ResourceCreationResult> createCustomer(
    CustomerInput input,
    String clientRequestId,
  ) async {
    final session = await _session();
    return _service.createCustomer(session.accessToken, input, clientRequestId);
  }

  @override
  Future<void> updateCustomer(String externalId, CustomerInput input) async {
    final session = await _session();
    await _service.updateCustomer(session.accessToken, externalId, input);
  }

  @override
  Future<void> changeStatus(String externalId, int statusId) async {
    final session = await _session();
    await _service.changeStatus(session.accessToken, externalId, statusId);
  }

  @override
  Future<ResourceCreationResult> addNote(
    String externalId,
    String text,
    String clientRequestId,
  ) async {
    final session = await _session();
    return _service.addNote(
      session.accessToken,
      externalId,
      text,
      clientRequestId,
    );
  }

  @override
  Future<ResourceCreationResult> addReminder(
    String externalId, {
    required String text,
    required DateTime reminderAtUtc,
    required String clientRequestId,
    String? assignedToId,
  }) async {
    final session = await _session();
    final requestedAssignee = assignedToId?.trim();
    final currentUserExternalId = session.user.externalId?.trim();
    return _service.addReminder(
      session.accessToken,
      externalId,
      text: text,
      reminderAtUtc: reminderAtUtc,
      clientRequestId: clientRequestId,
      assignedToId: requestedAssignee?.isNotEmpty == true
          ? requestedAssignee
          : currentUserExternalId,
    );
  }

  @override
  Future<void> completeReminder(
    String customerExternalId,
    String reminderExternalId,
    String clientRequestId,
  ) async {
    final session = await _session();
    await _service.completeReminder(
      session.accessToken,
      customerExternalId,
      reminderExternalId,
      clientRequestId,
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
