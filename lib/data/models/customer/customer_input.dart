class CustomerInput {
  const CustomerInput({
    required this.name,
    required this.companyName,
    required this.phone,
    required this.email,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.sellerExternalId,
  });

  factory CustomerInput.fromJson(Map<String, dynamic> json) => CustomerInput(
    name: json['name'] as String? ?? '',
    companyName: json['companyName'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String? ?? '',
    address: json['address'] as String? ?? '',
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    sellerExternalId: json['sellerExternalId'] as String?,
  );

  final String name;
  final String companyName;
  final String phone;
  final String email;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? sellerExternalId;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'companyName': companyName.trim(),
    'phone': phone.trim(),
    'email': email.trim(),
    'sellerExternalId': sellerExternalId,
    'address': address.trim(),
    'latitude': latitude,
    'longitude': longitude,
  };

  Map<String, dynamic> toCreateJson(String clientRequestId) => {
    ...toJson(),
    'clientRequestId': clientRequestId,
  };
}
