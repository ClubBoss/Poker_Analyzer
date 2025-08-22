import 'package:collection/collection.dart';

import '../models/training_recommendation.dart';
import 'weakness_cluster_engine.dart';
import '../models/training_result.dart';

class AdaptiveSchedulerService {
  AdaptiveSchedulerService();

  List<TrainingRecommendation> getNextRecommendations({
    required List<WeaknessCluster> clusters,
    required List<TrainingResult> history,
    required Map<String, double> tagMastery,
  }) {
    final List<TrainingRecommendation> recs = [];

    final mistakeScore = history.fold<int>(
      0,
      (p, r) => p + (r.total - r.correct),
    );
    if (mistakeScore > 0) {
      recs.add(
        TrainingRecommendation(
          title: '🔁 Повтор ошибок',
          type: TrainingRecommendationType.mistakeReplay,
          score: mistakeScore.toDouble(),
        ),
      );
    }

    final allTags = <String>{...tagMastery.keys, ...clusters.map((c) => c.tag)};
    for (final tag in allTags) {
      final mastery = tagMastery[tag] ?? 1.0;
      final severity =
          clusters.firstWhereOrNull((c) => c.tag == tag)?.severity ?? 0.0;
      if (mastery < 0.6) {
        final score = (0.6 - mastery) + severity;
        recs.add(
          TrainingRecommendation(
            title: '📊 Укрепить $tag',
            type: TrainingRecommendationType.weaknessDrill,
            goalTag: tag,
            score: score,
          ),
        );
      } else if (mastery < 0.8) {
        final score = (0.8 - mastery) + severity;
        recs.add(
          TrainingRecommendation(
            title: '📈 Закрепить $tag',
            type: TrainingRecommendationType.reinforce,
            goalTag: tag,
            score: score,
          ),
        );
      }
    }

    recs.sort((a, b) => b.score.compareTo(a.score));
    return recs;
  }
}
