import 'dart:convert';

Map<String, dynamic> toL3ExportRow({
  required String expected,
  required String chosen,
  required int elapsedMs,
  required String sessionId,
  required int ts,
  required String reason,
  required String packId,
}) {
  return {
    'expected': expected,
    'chosen': chosen,
    'elapsedMs': elapsedMs,
    'sessionId': sessionId,
    'ts': ts,
    'reason': reason,
    'packId': packId,
  };
}

String encodeJsonl(Iterable<Map<String, dynamic>> rows) {
  return rows.map(json.encode).join('\n');
}
