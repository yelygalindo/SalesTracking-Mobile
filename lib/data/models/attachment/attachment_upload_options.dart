class AttachmentUploadOptions {
  const AttachmentUploadOptions({
    required this.maxFileSizeBytes,
    required this.attachmentTypes,
    required this.acceptedFormats,
  });

  factory AttachmentUploadOptions.fromJson(Map<String, dynamic> json) =>
      AttachmentUploadOptions(
        maxFileSizeBytes: json['maxFileSizeBytes'] as int? ?? 0,
        attachmentTypes: _types(json['attachmentTypes']),
        acceptedFormats: _formats(json['acceptedFormats']),
      );

  final int maxFileSizeBytes;
  final List<AttachmentTypeOption> attachmentTypes;
  final List<AttachmentFormatOption> acceptedFormats;
}

class AttachmentTypeOption {
  const AttachmentTypeOption({
    required this.value,
    required this.label,
    required this.description,
  });

  factory AttachmentTypeOption.fromJson(Map<String, dynamic> json) =>
      AttachmentTypeOption(
        value: json['value'] as String? ?? '',
        label: json['label'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );

  final String value;
  final String label;
  final String description;
}

class AttachmentFormatOption {
  const AttachmentFormatOption({
    required this.description,
    required this.extensions,
    required this.contentTypes,
  });

  factory AttachmentFormatOption.fromJson(Map<String, dynamic> json) =>
      AttachmentFormatOption(
        description: json['description'] as String? ?? '',
        extensions: _strings(json['extensions']),
        contentTypes: _strings(json['contentTypes']),
      );

  final String description;
  final List<String> extensions;
  final List<String> contentTypes;
}

List<AttachmentTypeOption> _types(Object? value) => value is List
    ? value
          .whereType<Map<String, dynamic>>()
          .map(AttachmentTypeOption.fromJson)
          .toList(growable: false)
    : const [];

List<AttachmentFormatOption> _formats(Object? value) => value is List
    ? value
          .whereType<Map<String, dynamic>>()
          .map(AttachmentFormatOption.fromJson)
          .toList(growable: false)
    : const [];

List<String> _strings(Object? value) => value is List
    ? value.whereType<String>().toList(growable: false)
    : const [];
