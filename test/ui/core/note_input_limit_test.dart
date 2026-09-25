import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/ui/core/note_input_limit.dart';

void main() {
  test('accepts the boundary and rejects a longer pasted note', () {
    expect(validateNote(List.filled(maxNoteCharacters, 'a').join()), isNull);
    expect(
      validateNote(List.filled(maxNoteCharacters + 1, 'a').join()),
      contains('$maxNoteCharacters caracteres'),
    );
  });

  test('counts UTF-16 units to match server-side string validation', () {
    expect(
      validateNote(List.filled(maxNoteCharacters ~/ 2, '😊').join()),
      isNull,
    );
    expect(
      validateNote(List.filled(maxNoteCharacters ~/ 2 + 1, '😊').join()),
      isNotNull,
    );
  });

  test('rejects an oversized reminder before sending', () {
    expect(
      validateReminder(List.filled(maxReminderCharacters, 'a').join()),
      isNull,
    );
    expect(
      validateReminder(List.filled(maxReminderCharacters + 1, 'a').join()),
      contains('$maxReminderCharacters caracteres'),
    );
  });

  test('formatter preserves complete graphemes within the UTF-16 limit', () {
    const formatter = BackendLengthLimitingTextInputFormatter(5);
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: 'a😊b😊',
        selection: TextSelection.collapsed(offset: 6),
      ),
    );
    expect(result.text, 'a😊b');
    expect(result.text.length, 4);
    expect(result.selection.extentOffset, 4);
  });
}
