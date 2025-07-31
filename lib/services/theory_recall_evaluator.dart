import '../models/theory_mini_lesson_node.dart';
import '../models/v2/training_spot_v2.dart';
import 'booster_cooldown_service.dart';
import 'mini_lesson_progress_tracker.dart';

/// Scores theory lessons for recall based on relevance and recency.
class TheoryRecallEvaluator {
  final BoosterCooldownService cooldown;
  final MiniLessonProgressTracker progress;
  final double tagWeight;
  final double stageWeight;
  final double recencyWeight;
  final double cooldownPenalty;
  final double completionPenalty;

  const TheoryRecallEvaluator({
    BoosterCooldownService? cooldown,
    MiniLessonProgressTracker? progress,
    this.tagWeight = 1.0,
    this.stageWeight = 1.0,
    this.recencyWeight = 0.1,
    this.cooldownPenalty = 1.0,
    this.completionPenalty = 2.0,
  })  : cooldown = cooldown ?? BoosterCooldownService.instance,
        progress = progress ?? MiniLessonProgressTracker.instance;

  static final RegExp _stageRe = RegExp(r'^level\\d+\$', caseSensitive: false);

  String? _extractStage(Iterable<String> tags) {
    for (final t in tags) {
      final lc = t.trim().toLowerCase();
      if (_stageRe.hasMatch(lc)) return lc;
    }
    return null;
  }

  /// Returns [candidates] ordered by descending score for [spot].
  Future<List<TheoryMiniLessonNode>> rank(
    List<TheoryMiniLessonNode> candidates,
    TrainingSpotV2 spot,
  ) async {
    if (candidates.isEmpty) return [];
    final now = DateTime.now();
    final spotTags = {for (final t in spot.tags) t.trim().toLowerCase()};
    final spotStage = _extractStage(spot.tags);

    final entries = <_Entry>[];

    for (final lesson in candidates) {
      final lessonTags = {for (final t in lesson.tags) t.trim().toLowerCase()};
      final overlap = lessonTags.intersection(spotTags).length;

      double score = overlap * tagWeight;

      final lessonStage = lesson.stage?.toLowerCase() ?? _extractStage(lesson.tags);
      if (spotStage != null && lessonStage != null && spotStage == lessonStage) {
        score += stageWeight;
      }

      final last = await progress.lastViewed(lesson.id);
      if (last != null) {
        final days = now.difference(last).inDays.toDouble();
        score += days * recencyWeight;
      }

      if (await progress.isCompleted(lesson.id)) {
        score -= completionPenalty;
      }

      for (final tag in lessonTags.intersection(spotTags)) {
        final next = await cooldown.nextEligibleAt(lesson.id, tag);
        if (next != null && next.isAfter(now)) {
          final days = next.difference(now).inDays + 1;
          score -= days * cooldownPenalty;
        }
      }

      entries.add(_Entry(lesson, score));
    }

    entries.sort((a, b) => b.score.compareTo(a.score));
    return [for (final e in entries) e.lesson];
  }
}

class _Entry {
  final TheoryMiniLessonNode lesson;
  final double score;
  _Entry(this.lesson, this.score);
}
