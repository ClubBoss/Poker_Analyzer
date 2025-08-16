import 'package:test/test.dart';
import 'package:poker_analyzer/services/spot_importer.dart';
import 'package:poker_analyzer/ui/session_player/models.dart';

void main() {
  test('case-insensitive kind and field trimming', () {
    const json =
        '[{"kind":"CALLVSJAM","hand":" AKo ","pos":" BTN ","stack":" 10bb ","action":" push "}]';
    final report = SpotImporter.parse(json, kind: 'Json');
    expect(report.added, 1);
    expect(report.skipped, 0);
    expect(report.errors, isEmpty);
    final spot = report.spots.single;
    expect(spot.kind, SpotKind.callVsJam);
    expect(spot.hand, 'AKo');
    expect(spot.pos, 'BTN');
    expect(spot.stack, '10bb');
    expect(spot.action, 'push');
  });

  test('duplicate detection JSON', () {
    const json =
        '[{"kind":"callVsJam","hand":"AKo","pos":"BTN","stack":"10bb","action":"push"}, {"kind":"callVsJam","hand":"AKo","pos":"BTN","stack":"10bb","action":"push"}]';
    final report = SpotImporter.parse(json, kind: 'json');
    expect(report.added, 1);
    expect(report.skipped, 1);
    expect(report.errors.length, 1);
    expect(report.errors.first.startsWith('Duplicate spot:'), isTrue);
  });

  test('duplicate detection CSV', () {
    const csv =
        'kind,hand,pos,stack,action\ncallVsJam,AKo,BTN,10bb,push\ncallVsJam,AKo,BTN,10bb,push';
    final report = SpotImporter.parse(csv, kind: 'CSV');
    expect(report.added, 1);
    expect(report.skipped, 1);
    expect(report.errors.length, 1);
    expect(report.errors.first.startsWith('Duplicate spot:'), isTrue);
  });

  test('error cap at five messages', () {
    final items = List.generate(
      7,
      (i) => '{"kind":"x","hand":"h","pos":"p","stack":"s","action":"a"}',
    );
    final json = '[${items.join(',')}]';
    final report = SpotImporter.parse(json, kind: 'json');
    expect(report.added, 0);
    expect(report.skipped, 7);
    expect(report.errors.length, 5);
  });
}
