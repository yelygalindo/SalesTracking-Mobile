import '../models/common/resource_creation_result.dart';
import '../models/customer/customer_detail.dart';
import '../models/customer/customer_input.dart';
import '../models/customer/customer_page.dart';
import '../models/customer/customer_status.dart';

abstract interface class CustomerRepository {
  Future<CustomerPage> getCustomers({
    String? status,
    String? externalUserId,
    String? search,
    int page = 1,
    int pageSize = 20,
  });

  Future<List<CustomerStatus>> getStatuses();

  Future<CustomerDetail> getCustomer(String externalId);

  Future<ResourceCreationResult> createCustomer(
    CustomerInput input,
    String clientRequestId,
  );

  Future<void> updateCustomer(String externalId, CustomerInput input);

  Future<void> changeStatus(String externalId, int statusId);
}
