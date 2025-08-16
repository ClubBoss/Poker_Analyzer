import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/ui/session_player/models.dart';
import 'package:poker_analyzer/services/spot_importer.dart';

void main() {
  SpotImportReport r(String s, {String? format, String? kind}) =>
      SpotImporter.parse(s, format: format, kind: kind);

  String dupJson({int count = 2}) => '''
[
  ${List.generate(count, (_) => '{"kind":"callVsJam","hand":"AKo","pos":"BTN","stack":"10bb","action":"push"}').join(',')}
]''';

  group('SpotImporter.parse', () {
    test('JSON happy path', () {
      final rep = r(
        '[{"kind":"callVsJam","hand":"AKo","pos":"BTN","stack":"10bb","action":"push"}]',
        format: 'json',
      );
      expect(rep.added, 1);
      expect(rep.errors, isEmpty);
      final s = rep.spots.single;
      expect(s.kind, SpotKind.callVsJam);
      expect(s.hand, 'AKo');
      expect(s.pos, 'BTN');
      expect(s.stack, '10bb');
      expect(s.action, 'push');
    });

    test('CSV: BOM + ; separator + case-insensitive headers', () {
      const csv = '\uFEFFPos;Kind;Action;Stack;Hand\nBTN;callVsJam;push;10bb;AKo';
      final rep = r(csv, format: 'csv');
      expect(rep.added, 1);
      expect(rep.errors, isEmpty);
    });

    test('CSV: quoted value with comma', () {
      const csv =
          'kind;hand;pos;stack;action;explain\ncallVsJam;AKo;BTN;10bb;push;"reason,detail"';
      final rep = r(csv, format: 'csv');
      expect(rep.added, 1);
      expect(rep.spots.single.explain, 'reason,detail');
    });

    test('CSV: unescapes doubled quotes inside quoted fields', () {
      const csv = 'kind,hand,pos,stack,action,explain\n'
          'callVsJam,AKo,BTN,10bb,push,"He said ""jam"""';
      final rep = r(csv, format: 'csv');
      expect(rep.added, 1);
      expect(rep.spots.single.explain, 'He said "jam"');
    });

    test('Duplicate detection: one message, full counter', () {
      final rep = r(dupJson(count: 3), format: 'json');
      expect(rep.added, 1);
      expect(rep.skippedDuplicates, 2);
      expect(rep.errors.where((e) => e.startsWith('Duplicate spot:')).length, 1);
    });

    test('Unsupported format surfaces clear error', () {
      final rep = r('x', format: 'xml');
      expect(rep.added, 0);
      expect(rep.skipped, greaterThanOrEqualTo(1));
      expect(rep.errors.single.toLowerCase(), contains('unsupported format'));
    });

    test('Error cap at five messages', () {
      final items = List.generate(
        7,
        (i) => '{"kind":"x","hand":"h","pos":"p","stack":"s","action":"a"}',
      );
      final rep = r('[${items.join(',')}]', format: 'json');
      expect(rep.added, 0);
      expect(rep.skipped, 7);
      expect(rep.errors.length, 5);
    });

    test('Back-compat: legacy kind parameter still works', () {
      const csv = 'kind,hand,pos,stack,action\ncallVsJam,AKo,BTN,10bb,push';
      final rep = r(csv, kind: 'csv');
      expect(rep.added, 1);
      expect(rep.errors, isEmpty);
    });

    test('Precedence: format overrides kind when both provided', () {
      const csv = 'kind,hand,pos,stack,action\ncallVsJam,AKo,BTN,10bb,push';
      final rep = r(csv, format: 'csv', kind: 'json');
      expect(rep.added, 1);
      expect(rep.errors, isEmpty);
    });
  });
}
