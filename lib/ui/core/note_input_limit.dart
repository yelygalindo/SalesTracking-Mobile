import 'package:characters/characters.dart';
import 'package:flutter/services.dart';

/// A client-side safety limit for notes pasted from external documents.
const maxNoteCharacters = 2000;
const maxReminderCharacters = 500;

String? validateNote(String? value) {
  final note = value?.trim() ?? '';
  if (note.isEmpty) return 'Escribe una nota antes de guardarla.';
  // Dart/.NET string length counts UTF-16 code units; Flutter's maxLength
  // counts grapheme clusters and can therefore allow a longer backend value.
  if (note.length > maxNoteCharacters) {
    return 'La nota puede tener como máximo $maxNoteCharacters caracteres.';
  }
  return null;
}

String? validateReminder(String? value) {
  final reminder = value?.trim() ?? '';
  if (reminder.isEmpty) return 'Escribe un recordatorio antes de guardarlo.';
  if (reminder.length > maxReminderCharacters) {
    return 'El recordatorio puede tener como máximo '
        '$maxReminderCharacters caracteres.';
  }
  return null;
}

/// Caps UTF-16 length without cutting a visible character in half.
class BackendLengthLimitingTextInputFormatter extends TextInputFormatter {
  const BackendLengthLimitingTextInputFormatter(this.maxLength);

  final int maxLength;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length <= maxLength || !newValue.composing.isCollapsed) {
      return newValue;
    }
    final buffer = StringBuffer();
    for (final character in newValue.text.characters) {
      if (buffer.length + character.length > maxLength) break;
      buffer.write(character);
    }
    final truncated = buffer.toString();
    return newValue.copyWith(
      text: truncated,
      selection: TextSelection.collapsed(
        offset: newValue.selection.extentOffset.clamp(0, truncated.length),
      ),
      composing: TextRange.empty,
    );
  }
}
