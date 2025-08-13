import '../models/theory_mini_lesson_node.dart';
import '../models/mistake_tag_history_entry.dart';
import '../services/mistake_tag_history_service.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/booster_library_service.dart';

class BoosterRecommendationResult {
  final String boosterId;
  final String reasonTag;
  final double priority;
  final String origin;

  const BoosterRecommendationResult({
    required this.boosterId,
    required this.reasonTag,
    required this.priority,
    this.origin = '',
  });
}

class TheoryBoosterRecommender {
  final BoosterLibraryService library;

  const TheoryBoosterRecommender(
      {this.library = BoosterLibraryService.instance});

  Future<BoosterRecommendationResult?> recommend(
    TheoryMiniLessonNode lesson, {
    List<MistakeTagHistoryEntry>? recentMistakes,
  }) async {
    await library.loadAll();
    final tags = {for (final t in lesson.tags) t.trim().toLowerCase()}
      ..removeWhere((t) => t.isEmpty);
    if (tags.isEmpty) return null;

    recentMistakes ??=
        await MistakeTagHistoryService.getRecentHistory(limit: 50);

    final tagImpact = <String, double>{};
    for (final entry in recentMistakes) {
      final impact = entry.evDiff.abs();
      for (final tag in entry.tags) {
        final key = tag.label.toLowerCase();
        if (tags.contains(key)) {
          tagImpact.update(key, (v) => v + impact, ifAbsent: () => impact);
        }
      }
    }

    TrainingPackTemplateV2? best;
    String? bestTag;
    double bestScore = -1;

    for (final tag in tags) {
      final boosters = library.findByTag(tag);
      if (boosters.isEmpty) continue;
      final score = tagImpact[tag] ?? 0.0;
      if (score > bestScore) {
        best = boosters.first;
        bestTag = tag;
        bestScore = score;
      }
    }

    if (best == null) return null;

    return BoosterRecommendationResult(
      boosterId: best.id,
      reasonTag: bestTag ?? '',
      priority: bestScore,
      origin: 'lesson',
    );
  }
}
