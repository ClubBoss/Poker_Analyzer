import 'package:test/test.dart';
import '../lib/ui/session_player/models.dart';
import '../lib/services/spot_importer.dart';

void main() {
  test('parses JSON array of spots', () {
    final json = '''
  [
    {"kind":"l3_flop_jam_vs_raise","hand":"AhKd","pos":"BTN","stack":"20bb","action":"jam"},
    {"kind":"l3_turn_jam_vs_raise","hand":"QsQc","pos":"SB","stack":"15bb","action":"fold"}
  ]
  ''';
    final r = SpotImporter.parse(json, format: 'json');
    expect(r.errors, isEmpty);
    expect(r.added, 2);
    expect(r.skipped, 0);
    expect(
      r.spots.map((s) => s.kind),
      containsAll([
        SpotKind.l3_flop_jam_vs_raise,
        SpotKind.l3_turn_jam_vs_raise,
      ]),
    );
  });

  test('single JSON object is accepted via JSONL branch', () {
    final jsonObj =
        '{"kind":"l3_river_jam_vs_raise","hand":"T9s","pos":"BB","stack":"12bb","action":"fold"}';
    final r = SpotImporter.parse(jsonObj, format: 'json');
    expect(r.errors, isEmpty);
    expect(r.added, 1);
    expect(r.spots.single.kind, SpotKind.l3_river_jam_vs_raise);
  });

  test('JSONL invalid lines report row-scoped errors and cap at 5', () {
    final lines = [
      '{"kind":"l3_flop_jam_vs_raise","hand":"AKo","pos":"CO","stack":"25bb","action":"jam"}',
      '{bad json',
      '{also bad',
      'not even json',
      '{"kind":42}',
      '{"kind":"l3_flop_jam_vs_raise","hand":"AKo","pos":"CO","stack":"25bb","action":"jam"}',
      '{broken again',
    ].join('\n');

    final r = SpotImporter.parse(lines, format: 'json');
    expect(r.added, 1);
    expect(r.skippedDuplicates, 1);
    expect(r.skipped, greaterThanOrEqualTo(5));
    expect(r.errors.length, lessThanOrEqualTo(5));
  });

  test('dedupe key includes action: jam vs fold are not duplicates', () {
    final jsonl = [
      '{"kind":"l3_flop_jam_vs_raise","hand":"AhKd","pos":"BTN","stack":"20bb","action":"jam"}',
      '{"kind":"l3_flop_jam_vs_raise","hand":"AhKd","pos":"BTN","stack":"20bb","action":"fold"}',
    ].join('\n');

    final r = SpotImporter.parse(jsonl, format: 'json');
    expect(r.errors, isEmpty);
    expect(r.added, 2);
    expect(r.skippedDuplicates, 0);
  });
}
