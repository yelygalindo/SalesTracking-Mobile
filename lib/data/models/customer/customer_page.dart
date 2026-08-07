import 'customer_summary.dart';

class CustomerPage {
  const CustomerPage({
    required this.customers,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  factory CustomerPage.fromJson(Map<String, dynamic> json) {
    final rawCustomers = json['customers'];
    return CustomerPage(
      customers: rawCustomers is List
          ? rawCustomers
                .whereType<Map<String, dynamic>>()
                .map(CustomerSummary.fromJson)
                .toList(growable: false)
          : const [],
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      totalItems: json['totalItems'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }

  final List<CustomerSummary> customers;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;

  Map<String, dynamic> toJson() => {
    'customers': customers.map((customer) => customer.toJson()).toList(),
    'page': page,
    'pageSize': pageSize,
    'totalItems': totalItems,
    'totalPages': totalPages,
  };
}
