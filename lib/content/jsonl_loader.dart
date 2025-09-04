// ASCII-only; pure Dart (no new deps)

import 'dart:convert';
import 'jsonl_validator.dart';

/// Parses JSONL `source` into a list of JSON objects after strict validation.
/// Throws [FormatException] if validation fails or a line decodes to a non-object.
List<Map<String, Object?>> parseJsonl(
  String source, {
  String idField = 'id',
  bool asciiOnly = true,
}) {
  final report = validateJsonl(source, idField: idField, asciiOnly: asciiOnly);
  if (!report.ok) {
    final first = report.issues.isNotEmpty
        ? report.issues.first
        : const JsonlIssue(0, 'Unknown JSONL error');
    throw FormatException(
      'JSONL validation failed at line ${first.line}: ${first.message}',
    );
  }
  final out = <Map<String, Object?>>[];
  final lines = const LineSplitter().convert(source);
  for (var i = 0; i < lines.length; i++) {
    final raw = lines[i].trimRight();
    if (raw.isEmpty || raw.startsWith('#')) continue;
    final decoded = json.decode(raw);
    if (decoded is! Map<String, Object?>) {
      throw FormatException('Line ${i + 1}: expected JSON object');
    }
    out.add(decoded);
  }
  return out;
}
