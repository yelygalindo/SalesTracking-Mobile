final RegExp _emailPattern = RegExp(
  r"^[A-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?(?:\.[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?)+$",
  caseSensitive: false,
);

String? optionalEmailValidationError(String? value) {
  final normalized = value?.trim() ?? '';
  if (normalized.isEmpty) return null;
  return _emailPattern.hasMatch(normalized)
      ? null
      : 'Ingresa un correo válido.';
}
