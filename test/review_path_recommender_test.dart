import 'package:test/test.dart';
import 'package:poker_analyzer/services/review_path_recommender.dart';
import 'package:poker_analyzer/services/skill_loss_detector.dart';

void main() {
  test('suggestRecoveryPath ranks tags by urgency', () {
    final losses = [
      SkillLoss(tag: 'a', drop: 0.2, trend: ''),
      SkillLoss(tag: 'b', drop: 0.1, trend: ''),
    ];
    final clusters = [
      const MistakeCluster(tag: 'a', count: 4),
      const MistakeCluster(tag: 'c', count: 2),
    ];
    final missRates = {'a': 0.5, 'c': 0.6, 'b': 0.2};

    const recommender = ReviewPathRecommender();
    final result = recommender.suggestRecoveryPath(
      losses: losses,
      mistakeClusters: clusters,
      goalMissRatesByTag: missRates,
    );

    expect(result.length, 2);
    expect(result.first.tag, 'a');
    expect(result.first.urgencyScore, closeTo(2.3, 0.001));
    expect(result.last.tag, 'c');
    expect(result.last.urgencyScore, closeTo(0.5, 0.001));
  });
}
