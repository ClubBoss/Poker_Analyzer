import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/training_result.dart';
import 'package:poker_analyzer/services/weakness_cluster_engine.dart';
import 'package:poker_analyzer/services/adaptive_scheduler_service.dart';
import 'package:poker_analyzer/models/training_recommendation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const service = AdaptiveSchedulerService();

  test('returns sorted recommendations based on mistakes and mastery', () {
    final clusters = [
      const WeaknessCluster(
        tag: 'btn push',
        reason: 'many mistakes',
        severity: 0.5,
      ),
    ];
    final history = [
      TrainingResult(
        date: DateTime.now(),
        total: 10,
        correct: 7,
        accuracy: 70,
        tags: const ['btn push'],
      ),
      TrainingResult(
        date: DateTime.now(),
        total: 8,
        correct: 8,
        accuracy: 100,
        tags: const ['sb vs bb'],
      ),
    ];
    final mastery = {'btn push': 0.4, 'sb vs bb': 0.7};

    final list = service.getNextRecommendations(
      clusters: clusters,
      history: history,
      tagMastery: mastery,
    );

    expect(list.length, 3);
    expect(list.first.type, TrainingRecommendationType.mistakeReplay);
    expect(list[1].type, TrainingRecommendationType.weaknessDrill);
    expect(list[1].goalTag, 'btn push');
    expect(list[2].type, TrainingRecommendationType.reinforce);
    expect(list[2].goalTag, 'sb vs bb');
  });
}
