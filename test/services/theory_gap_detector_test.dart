import 'package:test/test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/theory_gap_detector.dart';
import 'package:poker_analyzer/services/skill_tag_coverage_tracker.dart';

void main() {
  group('TheoryGapDetector', () {
    test('detects and ranks theory gaps', () async {
      SharedPreferences.setMockInitialValues({});

      final coverage = SkillTagCoverageTracker();
      coverage.skillTagCounts.addAll({'preflop': 1, 'postflop': 5});

      final detector = TheoryGapDetector(
        clusters: {
          'preflop': ['pack1', 'pack2'],
          'postflop': ['pack3'],
          'icm': [],
        },
        coverageTracker: coverage,
        theoryIndex: {
          'preflop': ['t1'],
          'postflop': ['t2'],
        },
        linkStatus: {'pack1': true, 'pack2': false, 'pack3': false},
        topicUpdated: {
          'preflop': DateTime.now().subtract(const Duration(days: 40)),
        },
        targetCoveragePerTopic: 3,
      );

      final gaps = await detector.detectGaps();
      expect(gaps.length, 3);
      final preflop = gaps.firstWhere((g) => g.topic == 'preflop');
      expect(preflop.candidatePacks, ['pack2']);
      final saved = await detector.loadFromPrefs();
      expect(saved.length, 3);
      expect(detector.gapsNotifier.value.length, 3);
    });
  });
}
