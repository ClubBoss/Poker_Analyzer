import 'dart:convert';

// Returns CSV string or null if input is empty/invalid.
String? buildReportCsv(String content) {
  content = content.trim();
  if (content.isEmpty) return null;
  dynamic decoded;
  try {
    decoded = jsonDecode(content);
  } catch (_) {
    return null;
  }
  if (decoded is! Map) return null;
  final keys = decoded.keys.map((e) => e.toString()).toList()..sort();
  final b = StringBuffer()
    ..writeln('metric,value')
    ..writeln('"rootKeys",${decoded.length}');
  for (final k in keys) {
    final v = decoded[k];
    if (v is num) {
      b.writeln('"${k.replaceAll('"', '""')}",$v');
    } else if (v is List) {
      b.writeln('"array:${k.replaceAll('"', '""')}",${v.length}');
    }
  }
  return b.toString();
}
