import '../common/user_reference.dart';
import 'customer_note.dart';
import 'customer_reminder.dart';

class CustomerDetail {
  const CustomerDetail({
    required this.id,
    required this.externalId,
    required this.name,
    required this.companyName,
    required this.phone,
    required this.email,
    required this.statusId,
    required this.status,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.createdAtUtc,
    required this.seller,
    required this.notes,
    required this.reminders,
  });

  factory CustomerDetail.fromJson(Map<String, dynamic> json) {
    final seller = json['seller'];
    return CustomerDetail(
      id: json['id'] as int? ?? 0,
      externalId: json['externalId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      statusId: json['statusId'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAtUtc: _optionalDate(json['createdAt']),
      seller: seller is Map<String, dynamic>
          ? UserReference.fromJson(seller)
          : null,
      notes: _notes(json['notes']),
      reminders: _reminders(json['reminders']),
    );
  }

  final int id;
  final String externalId;
  final String name;
  final String companyName;
  final String phone;
  final String email;
  final int statusId;
  final String status;
  final String address;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAtUtc;
  final UserReference? seller;
  final List<CustomerNote> notes;
  final List<CustomerReminder> reminders;

  Map<String, dynamic> toJson() => {
    'id': id,
    'externalId': externalId,
    'name': name,
    'companyName': companyName,
    'phone': phone,
    'email': email,
    'statusId': statusId,
    'status': status,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'createdAt': createdAtUtc?.toUtc().toIso8601String(),
    'seller': seller?.toJson(),
    'notes': notes.map((note) => note.toJson()).toList(),
    'reminders': reminders.map((reminder) => reminder.toJson()).toList(),
  };
}

List<CustomerNote> _notes(Object? value) => value is List
    ? value
          .whereType<Map<String, dynamic>>()
          .map(CustomerNote.fromJson)
          .toList(growable: false)
    : const [];

List<CustomerReminder> _reminders(Object? value) => value is List
    ? value
          .whereType<Map<String, dynamic>>()
          .map(CustomerReminder.fromJson)
          .toList(growable: false)
    : const [];

DateTime? _optionalDate(Object? value) {
  return value is String ? DateTime.tryParse(value)?.toUtc() : null;
}
