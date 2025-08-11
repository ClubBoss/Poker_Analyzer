import 'package:test/test.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/skill_tag_coverage_tracker.dart';

void main() {
  group('SkillTagCoverageTracker', () {
    test('normalizes and counts tags', () {
      final tracker = SkillTagCoverageTracker();
      final spots = [
        TrainingPackSpot(id: '1', tags: ['OpenSB', 'PairedBoards']),
        TrainingPackSpot(id: '2', tags: ['opensb', 'Vs3betIP']),
      ];
      final coverage = tracker.getSkillTagCoverage(spots);
      expect(coverage['opensb'], 2);
      expect(coverage['pairedboards'], 1);
      expect(coverage['vs3betip'], 1);
    });

    test('applies min count filter', () {
      final tracker = SkillTagCoverageTracker();
      final spots = [
        TrainingPackSpot(id: '1', tags: ['a']),
        TrainingPackSpot(id: '2', tags: ['b']),
        TrainingPackSpot(id: '3', tags: ['a']),
      ];
      final coverage = tracker.getSkillTagCoverage(spots, minCount: 2);
      expect(coverage, {'a': 2});
    });

    test('computes category coverage and detects underrepresented', () {
      final tracker = SkillTagCoverageTracker(
        allTags: ['a1', 'a2', 'b1'],
        tagCategoryMap: {'a1': 'A', 'a2': 'A', 'b1': 'B'},
      );
      final spots = [
        TrainingPackSpot(id: '1', tags: ['a1']),
        TrainingPackSpot(id: '2', tags: ['b1']),
      ];
      tracker.analyze(spots);
      final report = tracker.aggregateReport;
      expect(report.categoryCounts['A'], 1);
      expect(report.categoryCounts['B'], 1);
      expect(report.categoryCoverage['A'], closeTo(0.5, 0.001));
      expect(report.categoryCoverage['B'], closeTo(1.0, 0.001));
      final under = tracker.underrepresentedCategories(threshold: 0.6);
      expect(under, ['A']);
    });
  });
}
