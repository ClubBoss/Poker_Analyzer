import 'package:test/test.dart';
import '../lib/ui/session_player/models.dart';
import '../lib/services/spot_importer.dart';

void main() {
  test('parse JSONL jam/fold spots and skip duplicates', () {
    final jsonl = [
      '{"kind":"l3_flop_jam_vs_raise","hand":"AhKd","pos":"BTN","stack":"20bb","action":"jam"}',
      '{"kind":"l3_flop_jam_vs_raise","hand":"AhKd","pos":"BTN","stack":"20bb","action":"jam"}', // dup
      '{"kind":"l3_turn_jam_vs_raise","hand":"QsQc","pos":"SB","stack":"15bb","action":"fold"}',
    ].join('\n');

    final report = SpotImporter.parse(jsonl, format: 'json');
    expect(report.errors, isEmpty);
    expect(report.added, 2); // 3 lines, 1 duplicate
    expect(report.skippedDuplicates, 1);
    expect(report.spots.length, 2);
    expect(report.spots.first.kind, SpotKind.l3_flop_jam_vs_raise);
  });

  test('ignores extra export fields: expected/chosen/elapsedMs', () {
    final jsonl = [
      '{"kind":"l3_river_jam_vs_raise","hand":"T9s","pos":"BB","stack":"12bb","action":"fold","expected":"fold","chosen":"jam","elapsedMs":840}',
    ].join('\n');

    final report = SpotImporter.parse(jsonl, format: 'json');
    expect(report.errors, isEmpty);
    expect(report.added, 1);
    expect(report.spots.single.kind, SpotKind.l3_river_jam_vs_raise);
    expect(
      report.spots.single.action,
      anyOf('jam', 'fold'),
    ); // parser keeps canonical 'action'
  });
}
