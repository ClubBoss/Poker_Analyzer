import 'dart:convert';

Iterable<Map<String, dynamic>> decodeJsonl(String src) sync* {
  for (final line in src.split('\n')) {
    if (line.trim().isEmpty) continue;
    final decoded = json.decode(line);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Expected JSON object');
    }
    yield Map<String, dynamic>.from(decoded);
  }
}
