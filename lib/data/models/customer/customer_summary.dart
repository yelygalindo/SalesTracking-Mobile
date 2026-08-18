import '../common/utc_date_time.dart';
import '../common/user_reference.dart';

class CustomerSummary {
  const CustomerSummary({
    required this.id,
    required this.externalId,
    required this.name,
    required this.companyName,
    required this.phone,
    required this.email,
    required this.status,
    required this.createdAtUtc,
    required this.seller,
  });

  factory CustomerSummary.fromJson(Map<String, dynamic> json) {
    final seller = json['seller'];
    return CustomerSummary(
      id: json['id'] as int? ?? 0,
      externalId: json['externalId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAtUtc: tryParseUtcDateTime(json['createdAt']),
      seller: seller is Map<String, dynamic>
          ? UserReference.fromJson(seller)
          : null,
    );
  }

  final int id;
  final String externalId;
  final String name;
  final String companyName;
  final String phone;
  final String email;
  final String status;
  final DateTime? createdAtUtc;
  final UserReference? seller;

  Map<String, dynamic> toJson() => {
    'id': id,
    'externalId': externalId,
    'name': name,
    'companyName': companyName,
    'phone': phone,
    'email': email,
    'status': status,
    'createdAt': createdAtUtc?.toUtc().toIso8601String(),
    'seller': seller?.toJson(),
  };
}
