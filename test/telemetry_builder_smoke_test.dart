import 'package:test/test.dart';
import '../lib/infra/telemetry_builder.dart';

void main() {
  group('telemetry builders', () {
    test('buildTheoryViewed', () {
      final m = buildTheoryViewed(moduleId: 'cash:l3:v1', theoryId: 't1');
      expect(m, isNotEmpty);
      expect(m['theoryId'], 't1');
    });

    test('buildDemoCompleted', () {
      final m = buildDemoCompleted(
        moduleId: 'cash:l3:v1',
        demoId: 'd1',
        ms: 123,
      );
      expect(m, isNotEmpty);
      expect(m['ms'], 123);
    });

    test('buildPracticeSpotAnswered', () {
      final m = buildPracticeSpotAnswered(
        moduleId: 'cash:l3:v1',
        spotId: 's42',
        correct: true,
        ms: 456,
      );
      expect(m, isNotEmpty);
      expect(m['correct'], isTrue);
    });

    test('buildModuleMastered', () {
      final m = buildModuleMastered(moduleId: 'icm:l4:bb:v1');
      expect(m, isNotEmpty);
      expect(m['moduleId'], 'icm:l4:bb:v1');
    });
  });
}
