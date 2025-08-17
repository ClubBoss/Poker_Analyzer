import 'package:test/test.dart';

import 'package:poker_analyzer/ui/session_player/l3_jsonl_export.dart';
import 'package:poker_analyzer/ui/session_player/l3_jsonl_decode.dart';

bool _isAscii(String s) => s.codeUnits.every((c) => c < 128);

void main() {
  test('round-trip decodeJsonl', () {
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
    final jsonl = encodeJsonl([row1, row2]);
    final extraLine =
        '{"expected":"jam","chosen":"fold","elapsedMs":1,"sessionId":"s3","ts":3333,"reason":"test","packId":"p3","extra":"x"}';
    final src = '$jsonl\n\n$extraLine\n\n';
    final decoded = decodeJsonl(src).toList();

    expect(decoded.length, 3);
    expect(decoded[0], row1);
    expect(decoded[1], row2);

    final third = decoded[2];
    expect(
      third.keys.toSet().containsAll([
        'expected',
        'chosen',
        'elapsedMs',
        'sessionId',
        'ts',
        'reason',
        'packId',
      ]),
      isTrue,
    );
    expect(third['extra'], 'x');

    for (final map in decoded) {
      for (final key in map.keys) {
        expect(_isAscii(key), isTrue);
      }
    }

    expect(
      () => decodeJsonl('{"expected":"jam"}\nnot-json'),
      throwsFormatException,
    );
  });
}
