import 'training_history_service_v2.dart';
import 'training_pack_tag_analytics_service.dart';
import 'training_stats_service.dart';

class TrainingTopicSuggestionEngine {
  TrainingTopicSuggestionEngine();

  Future<String?> suggestNextTag({
    Duration recent = const Duration(days: 3),
  }) async {
    final stats = TrainingStatsService.instance;
    if (stats == null) return null;

    final analytics = TrainingPackTagAnalyticsService();
    await analytics.loadStats();
    final popular = analytics.getPopularTags();
    if (popular.isEmpty) return null;

    // Recent mistakes and session history, used for weighting
    final mistakesDaily = stats.mistakesDaily(3);
    final recentMistakes = mistakesDaily.isNotEmpty
        ? mistakesDaily.last.value
        : 0;

    final history = await TrainingHistoryServiceV2.getHistory(limit: 50);
    final cutoff = DateTime.now().subtract(recent);
    final recentTags = <String>{};
    for (final entry in history) {
      if (entry.timestamp.isAfter(cutoff)) {
        for (final t in entry.tags) {
          final key = t.trim().toLowerCase();
          if (key.isNotEmpty) recentTags.add(key);
        }
      } else {
        break;
      }
    }

    TagAnalytics? best;
    double bestScore = -1;
    for (final t in popular) {
      final key = t.tag.trim().toLowerCase();
      if (recentTags.contains(key)) continue;
      final total = t.totalTrained;
      final mistakes = t.mistakes;
      final accuracy = total > 0 ? (total - mistakes) / total : 1.0;
      var score = (1 - accuracy) * (total.toDouble() + 1);
      if (recentMistakes > 0) score += mistakes.toDouble();
      if (score > bestScore) {
        bestScore = score;
        best = t;
      }
    }

    if (best == null) {
      TagAnalytics? alt;
      double altScore = -1;
      for (final t in popular.reversed) {
        final key = t.tag.trim().toLowerCase();
        if (recentTags.contains(key)) continue;
        final score = t.valueScore - t.launches.toDouble();
        if (score > altScore) {
          altScore = score;
          alt = t;
        }
      }
      return alt?.tag;
    }

    return best.tag;
  }
}
