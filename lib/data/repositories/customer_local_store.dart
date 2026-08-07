import '../models/customer/customer_detail.dart';
import '../models/customer/customer_page.dart';
import '../models/customer/customer_status.dart';
import '../models/customer/customer_summary.dart';
import '../models/customer/pending_customer_operation.dart';

abstract interface class CustomerLocalStore {
  Future<void> cacheCustomers(List<CustomerSummary> customers);

  Future<CustomerPage> readCustomers({
    String? status,
    String? search,
    int page = 1,
    int pageSize = 20,
  });

  Future<List<CustomerSummary>> readPendingCustomers();

  Future<void> cacheDetail(CustomerDetail customer);

  Future<CustomerDetail?> readDetail(String externalId);

  Future<void> cacheStatuses(List<CustomerStatus> statuses);

  Future<List<CustomerStatus>> readStatuses();

  Future<void> enqueueCreate(
    PendingCustomerOperation operation, {
    required CustomerSummary summary,
    required CustomerDetail detail,
  });

  Future<List<PendingCustomerOperation>> readPending();

  Future<int> pendingCount();

  Future<String?> serverIdForLocalId(String localCustomerId);

  Future<void> markCreateSynced(
    String requestId, {
    required String localCustomerId,
    required String serverCustomerId,
  });

  Future<void> recordFailure(String requestId, String message);
}
