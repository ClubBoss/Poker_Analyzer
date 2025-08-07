import 'package:test/test.dart';
import 'package:poker_analyzer/services/autogen_error_stats_logger.dart';
import 'package:poker_analyzer/services/autogen_pack_error_classifier_service.dart';

void main() {
  group('AutogenErrorStatsLogger', () {
    test('exportCsv outputs counts for each error type', () {
      final logger = AutogenErrorStatsLogger();
      logger.clear();
      logger.log(AutogenPackErrorType.duplicate);
      logger.log(AutogenPackErrorType.duplicate);
      logger.log(AutogenPackErrorType.noSpotsGenerated);

      final csv = logger.exportCsv().trim().split('\n');
      expect(csv.first, 'error_type,count');
      expect(csv.contains('duplicate,2'), isTrue);
      expect(csv.contains('noSpotsGenerated,1'), isTrue);
    });
  });
}
