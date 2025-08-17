import 'dart:convert';

import 'package:test/test.dart';

import '../lib/services/spot_importer.dart';
import '../lib/ui/session_player/l3_jsonl_export.dart';

void main() {
  test('JSONL importer round trip handles extras and blanks', () {
    final row1 = {
      'kind': 'l3_flop_jam_vs_raise',
      'hand': 'AhKd',
      'pos': 'BTN',
      'stack': '20bb',
      'action': 'jam',
      ...toL3ExportRow(
        expected: 'fold',
        chosen: 'jam',
        elapsedMs: 111,
        sessionId: 's1',
        ts: 1,
        reason: 'r1',
        packId: 'p1',
      ),
    };
    final row2 = {
      'kind': 'l3_turn_jam_vs_raise',
      'hand': 'QsQc',
      'pos': 'SB',
      'stack': '15bb',
      'action': 'fold',
      ...toL3ExportRow(
        expected: 'jam',
        chosen: 'fold',
        elapsedMs: 222,
        sessionId: 's1',
        ts: 2,
        reason: 'r2',
        packId: 'p1',
      ),
    };
    final jsonl = encodeJsonl([row1, row2]);

    final extraRow = {
      'kind': 'l3_river_jam_vs_raise',
      'hand': 'T9s',
      'pos': 'BB',
      'stack': '12bb',
      'action': 'jam',
      ...toL3ExportRow(
        expected: 'fold',
        chosen: 'jam',
        elapsedMs: 333,
        sessionId: 's1',
        ts: 3,
        reason: 'r3',
        packId: 'p1',
      ),
      'extra': 'x',
    };

    final text = [jsonl, '', json.encode(extraRow), '', ''].join('\n');

    final reportJson = SpotImporter.parse(text, format: 'json');
    expect(reportJson.spots.length, 3);
    expect(reportJson.added, 3);
    expect(reportJson.errors, isEmpty);

    final reportJsonl = SpotImporter.parse(text, format: 'jsonl');
    expect(reportJsonl.spots.length, 3);
    expect(reportJsonl.added, 3);
    expect(reportJsonl.errors, isEmpty);
  });
}
