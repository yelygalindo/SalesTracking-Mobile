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
}
