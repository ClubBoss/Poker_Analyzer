import 'package:test/test.dart';
import 'package:poker_analyzer/services/spot_importer.dart';
import 'package:poker_analyzer/ui/session_player/models.dart';

void main() {
  test('case-insensitive kind and field trimming', () {
    const json =
        '[{"kind":"CALLVSJAM","hand":" AKo ","pos":" BTN ","stack":" 10bb ","action":" push "}]';
    final report = SpotImporter.parse(json, format: 'Json');
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
    final report = SpotImporter.parse(json, format: 'json');
    expect(report.added, 1);
    expect(report.skipped, 1);
    expect(report.skippedDuplicates, 1);
    expect(report.errors.length, 1);
    expect(report.errors.first.startsWith('Duplicate spot:'), isTrue);
  });

  test('duplicate detection CSV', () {
    const csv =
        'kind,hand,pos,stack,action\ncallVsJam,AKo,BTN,10bb,push\ncallVsJam,AKo,BTN,10bb,push';
    final report = SpotImporter.parse(csv, format: 'CSV');
    expect(report.added, 1);
    expect(report.skipped, 1);
    expect(report.skippedDuplicates, 1);
    expect(report.errors.length, 1);
    expect(report.errors.first.startsWith('Duplicate spot:'), isTrue);
  });

  test('error cap at five messages', () {
    final items = List.generate(
      7,
      (i) => '{"kind":"x","hand":"h","pos":"p","stack":"s","action":"a"}',
    );
    final json = '[${items.join(',')}]';
    final report = SpotImporter.parse(json, format: 'json');
    expect(report.added, 0);
    expect(report.skipped, 7);
    expect(report.errors.length, 5);
  });

  test('CSV tolerates column order and extra headers', () {
    const csv =
        'pos,kind,action,stack,hand,extra\nBTN,callVsJam,push,10bb,AKo,foo';
    final report = SpotImporter.parse(csv, format: 'csv');
    expect(report.added, 1);
    expect(report.errors, isEmpty);
    final spot = report.spots.single;
    expect(spot.kind, SpotKind.callVsJam);
    expect(spot.hand, 'AKo');
    expect(spot.pos, 'BTN');
    expect(spot.stack, '10bb');
    expect(spot.action, 'push');
  });

  test('JSON unknown kind is skipped', () {
    const json =
        '[{"kind":"UnKnOwN","hand":"AKo","pos":"BTN","stack":"10bb","action":"push"}]';
    final report = SpotImporter.parse(json, format: 'json');
    expect(report.added, 0);
    expect(report.skipped, 1);
    expect(report.errors.single.contains('unknown kind'), isTrue);
  });

  test('CSV row with empty required field is skipped', () {
    const csv = 'kind,hand,pos,stack,action\ncallVsJam,,BTN,10bb,push';
    final report = SpotImporter.parse(csv, format: 'csv');
    expect(report.added, 0);
    expect(report.skipped, 1);
    expect(report.errors.single.contains('missing field'), isTrue);
  });

  test('CSV with BOM and semicolon delimiter', () {
    const csv = '\uFEFFPos;Kind;Action;Stack;Hand\nBTN;callVsJam;push;10bb;AKo';
    final report = SpotImporter.parse(csv, format: 'csv');
    expect(report.added, 1);
    expect(report.errors, isEmpty);
    final spot = report.spots.single;
    expect(spot.kind, SpotKind.callVsJam);
    expect(spot.hand, 'AKo');
    expect(spot.pos, 'BTN');
    expect(spot.stack, '10bb');
    expect(spot.action, 'push');
  });

  test('CSV quoted value with comma', () {
    const csv =
        'kind;hand;pos;stack;action;explain\ncallVsJam;AKo;BTN;10bb;push;"reason,detail"';
    final report = SpotImporter.parse(csv, format: 'csv');
    expect(report.added, 1);
    final spot = report.spots.single;
    expect(spot.explain, 'reason,detail');
  });
}
