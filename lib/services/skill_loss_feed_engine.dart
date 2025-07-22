import 'skill_loss_detector.dart';
import 'tag_goal_tracker_service.dart';
import 'pack_library_service.dart';

class SkillLossFeedItem {
  final String tag;
  final double urgencyScore;
  final String trend;
  final String? suggestedPackId;

  const SkillLossFeedItem({
    required this.tag,
    required this.urgencyScore,
    required this.trend,
    this.suggestedPackId,
  });
}

class SkillLossFeedEngine {
  final TagGoalTrackerService _goals;
  final PackLibraryService _library;

  const SkillLossFeedEngine({
    TagGoalTrackerService? goals,
    PackLibraryService? library,
  }) : _goals = goals ?? TagGoalTrackerService.instance,
       _library = library ?? PackLibraryService.instance;

  Future<List<SkillLossFeedItem>> buildFeed(
    List<SkillLoss> losses, {
    DateTime? now,
    int maxItems = 3,
  }) async {
    if (losses.isEmpty) return [];
    final current = now ?? DateTime.now();

    final scored = <_ScoredItem>[];

    for (final loss in losses) {
      final progress = await _goals.getProgress(loss.tag);
      final last = progress.lastTrainingDate;
      final daysSince = last == null
          ? 30
          : current.difference(last).inDays.clamp(0, 30);
      final recencyFactor = 1 + daysSince / 7;
      final score = loss.drop * recencyFactor;

      final pack = await _library.findByTag(loss.tag);
      scored.add(
        _ScoredItem(
          item: SkillLossFeedItem(
            tag: loss.tag,
            urgencyScore: score,
            trend: loss.trend,
            suggestedPackId: pack?.id,
          ),
          score: score,
        ),
      );
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((e) => e.item).take(maxItems).toList();
  }
}

class _ScoredItem {
  final SkillLossFeedItem item;
  final double score;
  const _ScoredItem({required this.item, required this.score});
}
