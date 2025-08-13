import 'package:test/test.dart';
import 'package:poker_analyzer/utils/report_csv.dart';

void main() {
  group('buildReportCsv', () {
    test('produces expected metrics', () {
      final json = '{"b":2,"a":[1,2,3],"c":"ignore"}';
      final csv = buildReportCsv(json);
      expect(csv, isNotNull);
      final lines = csv!.trim().split('\n');
      expect(lines.first, 'metric,value');
      expect(lines[1], '"rootKeys",3');
      expect(lines[2], '"array:a",3');
      expect(lines[3], '"b",2');
      expect(lines.length, 4);
    });

    test('invalid or empty json returns null', () {
      expect(buildReportCsv(''), isNull);
      expect(buildReportCsv('not json'), isNull);
      expect(buildReportCsv('[]'), isNull);
    });
  });
}
