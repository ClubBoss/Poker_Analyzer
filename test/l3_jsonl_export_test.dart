import 'dart:convert';

import 'package:test/test.dart';

import 'package:poker_analyzer/ui/session_player/l3_jsonl_export.dart';

void main() {
  test('encode and decode JSONL rows', () {
    final row1 = toL3ExportRow(
      expected: 'fold',
      chosen: 'jam',
      elapsedMs: 1234,
      sessionId: 's1',
      ts: 1111,
      reason: 'demo',
      packId: 'p1',
    );
    final row2 = toL3ExportRow(
      expected: 'jam',
      chosen: 'fold',
      elapsedMs: 5678,
      sessionId: 's2',
      ts: 2222,
      reason: 'prod',
      packId: 'p2',
    );

    final encoded = encodeJsonl([row1, row2]);
    final lines = encoded.split('\n');
    expect(lines.length, 2);
    expect(lines.contains(''), isFalse);

    final decoded1 = json.decode(lines[0]) as Map<String, dynamic>;
    final decoded2 = json.decode(lines[1]) as Map<String, dynamic>;
    expect(decoded1, row1);
    expect(decoded2, row2);

    for (final decoded in [decoded1, decoded2]) {
      for (final key in decoded.keys) {
        for (final code in key.codeUnits) {
          expect(code < 128, isTrue, reason: 'Non-ASCII key: $key');
        }
      }
    }
  });
}
