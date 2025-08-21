import '../models/pinned_learning_item.dart';
import 'pinned_learning_service.dart';
import 'decay_tag_retention_tracker_service.dart';
import 'training_progress_service.dart';
import 'lesson_progress_service.dart';
import 'mini_lesson_library_service.dart';
import 'pack_library_service.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/theory_mini_lesson_node.dart';
import 'theory_block_library_service.dart';
import 'theory_path_completion_evaluator_service.dart';
import 'user_progress_service.dart';

/// Chooses the best pinned item to resume next based on simple heuristics.
class SmartPinnedRecommenderService {
  SmartPinnedRecommenderService({
    PinnedLearningService? pinned,
    DecayTagRetentionTrackerService? retention,
    TrainingProgressService? training,
    LessonProgressService? lessons,
  }) : _pinned = pinned ?? PinnedLearningService.instance,
       _retention = retention ?? const DecayTagRetentionTrackerService(),
       _training = training ?? TrainingProgressService.instance,
       _lessons = lessons ?? LessonProgressService.instance;

  final PinnedLearningService _pinned;
  final DecayTagRetentionTrackerService _retention;
  final TrainingProgressService _training;
  final LessonProgressService _lessons;

  /// Returns the most relevant [PinnedLearningItem] to continue, or `null`
  /// if no item stands out.
  Future<PinnedLearningItem?> recommendNext() async {
    final items = _pinned.items;
    if (items.isEmpty) return null;

    PinnedLearningItem? best;
    var bestScore = double.negativeInfinity;

    await TheoryBlockLibraryService.instance.loadAll();
    for (final item in items) {
      var score = 0.0;
      final tags = <String>[];

      if (item.type == 'pack') {
        final TrainingPackTemplateV2? tpl = await PackLibraryService.instance
            .getById(item.id);
        if (tpl != null) {
          tags.addAll(tpl.tags.map((e) => e.trim().toLowerCase()));
          final prog = await _training.getProgress(item.id);
          score += (1 - prog) * 6; // Low completion => higher weight
        }
      } else if (item.type == 'lesson') {
        await MiniLessonLibraryService.instance.loadAll();
        final TheoryMiniLessonNode? lesson = MiniLessonLibraryService.instance
            .getById(item.id);
        if (lesson != null) {
          tags.addAll(lesson.tags.map((e) => e.trim().toLowerCase()));
          final completed = await _lessons.isCompleted(item.id);
          if (!completed) score += 6; // Incomplete lesson
        }
      } else if (item.type == 'block') {
        final block = TheoryBlockLibraryService.instance.getById(item.id);
        if (block != null) {
          tags.addAll(block.tags.map((e) => e.trim().toLowerCase()));
          final evaluator = TheoryPathCompletionEvaluatorService(
            userProgress: UserProgressService.instance,
          );
          final pct = await evaluator.getBlockCompletionPercent(block);
          score += (1 - pct) * 6;
        }
      }

      // High decay urgency for any associated tag.
      for (final t in tags) {
        final days = await _retention.getDecayScore(t);
        if (days > 30) {
          // Consider tags older than 30 days as high decay
          score += 10;
          break;
        }
      }

      // Not seen recently
      if (item.lastSeen == null ||
          DateTime.now().difference(
                DateTime.fromMillisecondsSinceEpoch(item.lastSeen!),
              ) >
              const Duration(days: 7)) {
        score += 3;
      }

      // Penalize if opened many times already
      if (item.openCount >= 5) score -= 3;

      if (score > bestScore) {
        bestScore = score;
        best = item;
      }
    }

    // Only return a recommendation if the best item has a positive score.
    if (bestScore <= 0) return null;
    return best;
  }
}
