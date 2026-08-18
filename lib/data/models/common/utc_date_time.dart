DateTime? tryParseUtcDateTime(Object? value) {
  if (value is! String) return null;
  final text = value.trim();
  if (text.isEmpty) return null;
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return null;
  if (parsed.isUtc || _hasExplicitOffset(text)) return parsed.toUtc();
  return DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond,
    parsed.microsecond,
  );
}

DateTime parseUtcDateTime(Object? value) =>
    tryParseUtcDateTime(value) ??
    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

bool _hasExplicitOffset(String value) =>
    RegExp(r'(?:[zZ]|[+-]\d{2}:?\d{2})$').hasMatch(value);
