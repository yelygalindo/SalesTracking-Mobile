class ProjectStatus {
  const ProjectStatus({required this.value, required this.label});

  factory ProjectStatus.fromJson(Map<String, dynamic> json) => ProjectStatus(
    value: json['value'] as int? ?? 0,
    label: json['label'] as String? ?? '',
  );

  final int value;
  final String label;

  Map<String, dynamic> toJson() => {'value': value, 'label': label};
}
