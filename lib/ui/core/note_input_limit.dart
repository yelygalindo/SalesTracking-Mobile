import 'package:characters/characters.dart';

/// A client-side safety limit for notes pasted from external documents.
const maxNoteCharacters = 2000;

String? validateNote(String? value) {
  final note = value?.trim() ?? '';
  if (note.isEmpty) return 'Escribe una nota antes de guardarla.';
  if (note.characters.length > maxNoteCharacters) {
    return 'La nota puede tener como máximo $maxNoteCharacters caracteres.';
  }
  return null;
}
