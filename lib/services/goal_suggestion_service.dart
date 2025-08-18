import '../models/training_goal.dart';
import 'smart_recommender_engine.dart';
import 'tag_mastery_service.dart';

/// Suggests short-term training goals based on user's weaknesses.
class GoalSuggestionService {
  final SmartRecommenderEngine engine;
  final TagMasteryService mastery;

  GoalSuggestionService({SmartRecommenderEngine? engine, required this.mastery})
    : engine = engine ?? SmartRecommenderEngine(masteryService: mastery);

  /// Returns a list of up to three high-impact goals sorted by weakness severity.
  Future<List<TrainingGoal>> suggestGoals({
    required UserProgress progress,
  }) async {
    final masteryMap = await mastery.computeMastery();
    final clusters = engine.clusterEngine.detectWeaknesses(
      results: progress.history,
      tagMastery: masteryMap,
    );

    final goals = <TrainingGoal>[];
    final used = <String>{};

    for (final c in clusters) {
      final tag = c.tag.toLowerCase();
      if (masteryMap[tag] != null && masteryMap[tag]! >= 0.85) continue;
      if (!used.add(tag)) continue;
      final mapping = _tagGoals[tag];
      final title = mapping?['title'] ?? 'Улучшить игру $tag';
      final desc =
          mapping?['description'] ?? 'Закрой хотя бы 3 стадии с этим тегом';
      goals.add(TrainingGoal(title, description: desc, tag: tag));
      if (goals.length >= 3) break;
    }

    return goals;
  }

  static const Map<String, Map<String, String>> _tagGoals = {
    'sbvsbb': {
      'title': 'Улучшить игру SB vs BB',
      'description': 'Закрой хотя бы 3 стадии с этим тегом',
    },
    'openfold': {
      'title': 'Отработать open/fold',
      'description': 'Закрой хотя бы 3 стадии с этим тегом',
    },
  };
}
