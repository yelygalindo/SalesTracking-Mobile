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
