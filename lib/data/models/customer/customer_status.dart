class CustomerStatus {
  const CustomerStatus({required this.value, required this.label});

  factory CustomerStatus.fromJson(Map<String, dynamic> json) => CustomerStatus(
    value: json['value'] as int? ?? 0,
    label: json['label'] as String? ?? '',
  );

  final int value;
  final String label;

  Map<String, dynamic> toJson() => {'value': value, 'label': label};
}
