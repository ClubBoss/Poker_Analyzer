import 'package:test/test.dart';
import 'package:poker_analyzer/services/spot_importer.dart';

void main() {
  group('SpotImporter.parse smoke', () {
    const jsonl =
        '''{"kind":"l4_icm_bb_jam_vs_fold","hand":"Ah2h","pos":"bb","vsPos":"sb","stack":"10 bb","action":"jam"}
{"kind":"l4_icm_bb_jam_vs_fold","hand":"KdQc","pos":"bb","vsPos":"sb","stack":"12 bb","action":"jam"}''';

    const jsonArray =
        '''[{"kind":"l4_icm_bb_jam_vs_fold","hand":"Ah2h","pos":"bb","vsPos":"sb","stack":"10 bb","action":"jam"},
{"kind":"l4_icm_bb_jam_vs_fold","hand":"KdQc","pos":"bb","vsPos":"sb","stack":"12 bb","action":"jam"}]''';

    test('Autodetect JSONL', () {
      final report = SpotImporter.parse(jsonl);
      expect(report.spots, hasLength(2));
      expect(report.added, 2);
      expect(report.skippedDuplicates, 0);
      expect(report.errors, isEmpty);
    });

    test('JSON path tolerant to JSONL', () {
      final report = SpotImporter.parse(jsonl, format: 'json');
      expect(report.spots, hasLength(2));
      expect(report.added, 2);
      expect(report.skippedDuplicates, 0);
      expect(report.errors, isEmpty);
    });

    test('Autodetect JSON array', () {
      final report = SpotImporter.parse(jsonArray);
      expect(report.spots, hasLength(2));
      expect(report.added, 2);
      expect(report.skippedDuplicates, 0);
      expect(report.errors, isEmpty);
    });

    test('CSV', () {
      const csv = '''kind;hand;pos;vsPos;stack;action
l4_icm_bb_jam_vs_fold;Ah2h;bb;sb;10 bb;jam
l4_icm_bb_jam_vs_fold;KdQc;bb;sb;12 bb;jam''';
      final report = SpotImporter.parse(csv, format: 'csv');
      expect(report.spots, hasLength(2));
      expect(report.added, 2);
      expect(report.skippedDuplicates, 0);
      expect(report.errors, isEmpty);
    });

    test('JSONL duplicate rows are reported and deduped', () {
      const jsonlDup =
          '''{"kind":"l4_icm_bb_jam_vs_fold","hand":"Ah2h","pos":"bb","vsPos":"sb","stack":"10 bb","action":"jam"}
{"kind":"l4_icm_bb_jam_vs_fold","hand":"Ah2h","pos":"bb","vsPos":"sb","stack":"10 bb","action":"jam"}''';
      final report = SpotImporter.parse(jsonlDup);
      expect(report.spots.length, 1);
      expect(report.added, 1);
      expect(report.skippedDuplicates, 1);
      expect(report.errors, isNotEmpty);
    });
  });
}
