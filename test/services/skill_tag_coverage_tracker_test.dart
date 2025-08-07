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
  });
}
