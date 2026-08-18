class ProjectStatus {
  const ProjectStatus({required this.value, required this.label});

  factory ProjectStatus.fromJson(Map<String, dynamic> json) {
    final value = json['value'] as int? ?? 0;
    return ProjectStatus(
      value: value,
      label: value == 5
          ? 'Perdido'
          : normalizeProjectStatusLabel(json['label'] as String? ?? ''),
    );
  }

  final int value;
  final String label;

  Map<String, dynamic> toJson() => {'value': value, 'label': label};
}

String normalizeProjectStatusLabel(String value) {
  final normalized = value.trim().toLowerCase();
  return switch (normalized) {
    'cancelado' || 'cancelled' || 'canceled' => 'Perdido',
    _ => value,
  };
}
