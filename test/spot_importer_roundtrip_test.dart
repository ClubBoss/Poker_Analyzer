import 'package:test/test.dart';
import '../lib/services/spot_importer.dart';

void main() {
  test('CSV importer round trip handles extra fields', () {
    final csv = [
      'kind,hand,pos,stack,action,expected,chosen,elapsedMs,sessionId,ts,reason,packId,extra',
      'l3_flop_jam_vs_raise,AhKd,BTN,20bb,jam,fold,jam,111,s1,1,r1,p1,',
      'l3_turn_jam_vs_raise,QsQc,SB,15bb,fold,jam,fold,222,s1,2,r2,p1,ignored',
    ].join('\n');

    final report = SpotImporter.parse(csv, format: 'csv');
    expect(report.spots.length, 2);
    expect(report.added, 2);
    expect(report.errors, isEmpty);
  });

  test('JSON importer round trip handles extra fields', () {
    final json = '''
[
  {
    "kind":"l3_flop_jam_vs_raise",
    "hand":"AhKd",
    "pos":"BTN",
    "stack":"20bb",
    "action":"jam",
    "expected":"fold",
    "chosen":"jam",
    "elapsedMs":111,
    "sessionId":"s1",
    "ts":1,
    "reason":"r1",
    "packId":"p1"
  },
  {
    "kind":"l3_turn_jam_vs_raise",
    "hand":"QsQc",
    "pos":"SB",
    "stack":"15bb",
    "action":"fold",
    "expected":"jam",
    "chosen":"fold",
    "elapsedMs":222,
    "sessionId":"s1",
    "ts":2,
    "reason":"r2",
    "packId":"p1",
    "extra":"ignored"
  }
]
''';

    final report = SpotImporter.parse(json, format: 'json');
    expect(report.spots.length, 2);
    expect(report.added, 2);
    expect(report.errors, isEmpty);
  });
}
