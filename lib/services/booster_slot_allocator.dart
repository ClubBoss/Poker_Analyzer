import '../models/theory_mini_lesson_node.dart';
import '../models/v2/training_spot_v2.dart';
import '../models/evaluation_result.dart';
import 'booster_path_history_service.dart';
import 'inbox_booster_tracker_service.dart';
import 'inbox_booster_tuner_service.dart';
import 'recap_effectiveness_analyzer.dart';

/// Delivery slots for booster lessons.
enum BoosterSlot { recap, inbox, goal, none }

/// Decision describing where a booster lesson should appear.
class BoosterSlotDecision {
  final String lessonId;
  final String tag;
  final String slot; // 'recap', 'inbox', or 'goal'

  BoosterSlotDecision({
    required this.lessonId,
    required this.tag,
    required this.slot,
  });
}

/// Allocates boosters to delivery slots based on user engagement context.
class BoosterSlotAllocator {
  final InboxBoosterTrackerService tracker;
  final BoosterPathHistoryService history;
  final InboxBoosterTunerService tuner;
  final RecapEffectivenessAnalyzer recap;

  BoosterSlotAllocator({
    InboxBoosterTrackerService? tracker,
    BoosterPathHistoryService? history,
    InboxBoosterTunerService? tuner,
    RecapEffectivenessAnalyzer? recap,
  }) : tracker = tracker ?? InboxBoosterTrackerService.instance,
       history = history ?? BoosterPathHistoryService.instance,
       tuner = tuner ?? InboxBoosterTunerService.instance,
       recap = recap ?? RecapEffectivenessAnalyzer.instance;

  static final BoosterSlotAllocator instance = BoosterSlotAllocator();

  /// Returns a slot decision for each lesson in [lessons]. Lessons recently
  /// surfaced via inbox or recap will be ignored.
  Future<List<BoosterSlotDecision>> allocateSlots(
    List<TheoryMiniLessonNode> lessons,
  ) async {
    if (lessons.isEmpty) return [];

    final histMap = await history.getTagStats();
    final scoreMap = await tuner.computeTagBoostScores();
    await recap.refresh();

    final result = <BoosterSlotDecision>[];
    for (final lesson in lessons) {
      if (await tracker.wasRecentlyShown(lesson.id)) continue;
      final tag = lesson.tags.isEmpty
          ? ''
          : lesson.tags.first.trim().toLowerCase();
      if (tag.isEmpty) continue;

      final hist = histMap[tag];
      if (hist != null &&
          DateTime.now().difference(hist.lastInteraction) <
              Duration(days: 1)) {
        continue; // recently repeated
      }

      final score = scoreMap[tag] ?? 1.0;
      final stats = recap.stats[tag];
      final urgency = stats == null
          ? 0.0
          : 1 / (stats.count + 1) +
                1 / (stats.averageDuration.inSeconds + 1) +
                (1 - stats.repeatRate);

      String slot;
      if (stats != null && urgency > 1.8) {
        slot = 'recap';
      } else if ((hist == null || hist.shownCount + hist.completedCount < 2) &&
          score > 1.5) {
        slot = 'goal';
      } else {
        slot = 'inbox';
      }

      result.add(
        BoosterSlotDecision(lessonId: lesson.id, tag: tag, slot: slot),
      );
    }

    return result;
  }

  /// Determines the best slot for [lesson] given training [spot].
  Future<BoosterSlot> decideSlot(
    TheoryMiniLessonNode lesson,
    TrainingSpotV2 spot,
  ) async {
    if (await tracker.wasRecentlyShown(lesson.id)) {
      return BoosterSlot.none;
    }

    final lessonTags = {for (final t in lesson.tags) t.trim().toLowerCase()}
      ..removeWhere((e) => e.isEmpty);
    final spotTags = {for (final t in spot.tags) t.trim().toLowerCase()}
      ..removeWhere((e) => e.isEmpty);
    if (lessonTags.intersection(spotTags).isEmpty) {
      return BoosterSlot.none;
    }

    final eval = spot.evalResult;
    final mistake = eval != null && !eval.correct;
    if (mistake) {
      final loss = _evLoss(eval);
      final critical = spot.priority <= 1 || loss > 1.0;
      return critical ? BoosterSlot.recap : BoosterSlot.inbox;
    }

    if (spot.priority <= 2) {
      return BoosterSlot.goal;
    }

    return BoosterSlot.none;
  }

  double _evLoss(EvaluationResult eval) {
    if (eval.ev != null) return eval.ev!.abs();
    if (eval.icmEv != null) return eval.icmEv!.abs();
    return (eval.expectedEquity - eval.userEquity).abs();
  }
}
