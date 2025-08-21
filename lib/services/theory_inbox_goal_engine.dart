import '../models/theory_mini_lesson_node.dart';
import '../models/xp_guided_goal.dart';
import 'booster_suggestion_engine.dart';
import 'inbox_booster_tracker_service.dart';
import 'recap_effectiveness_analyzer.dart';
import 'goal_progress_persistence_service.dart';
import '../utils/singleton_mixin.dart';

class TheoryInboxGoalEngine with SingletonMixin<TheoryInboxGoalEngine> {
  final BoosterSuggestionEngine booster;
  final InboxBoosterTrackerService tracker;
  final RecapEffectivenessAnalyzer recap;

  TheoryInboxGoalEngine({
    BoosterSuggestionEngine? booster,
    InboxBoosterTrackerService? tracker,
    RecapEffectivenessAnalyzer? recap,
  }) : booster = booster ?? const BoosterSuggestionEngine(),
       tracker = tracker ?? InboxBoosterTrackerService.instance,
       recap = recap ?? RecapEffectivenessAnalyzer.instance;

  static TheoryInboxGoalEngine get instance =>
      SingletonMixin.instance<TheoryInboxGoalEngine>(
        () => TheoryInboxGoalEngine(),
      );

  Future<List<XPGuidedGoal>> generateGoals({int maxGoals = 2}) async {
    if (maxGoals <= 0) return [];
    final lessons = await booster.getRecommendedBoosters(
      maxCount: maxGoals * 3,
    );
    if (lessons.isEmpty) return [];

    await recap.refresh();
    final interactionMap = await tracker.getInteractionStats();

    final items = <_Candidate>[];
    for (final l in lessons) {
      if (await tracker.wasRecentlyShown(l.id)) continue;
      final tag = l.tags.isNotEmpty ? l.tags.first.toLowerCase() : '';
      final stat = recap.stats[tag];
      final urgency = stat == null
          ? 0.0
          : 1 / (stat.count + 1) +
                1 / (stat.averageDuration.inSeconds + 1) +
                (1 - stat.repeatRate);
      final clicks = interactionMap[l.id]?['clicks'] as int? ?? 0;
      final score = urgency - clicks * 0.1;
      items.add(_Candidate(l, score));
    }

    items.sort((a, b) => b.score.compareTo(a.score));
    final goals = <XPGuidedGoal>[];
    for (final c in items.take(maxGoals)) {
      final l = c.lesson;
      goals.add(
        XPGuidedGoal(
          id: l.id,
          label: l.resolvedTitle,
          xp: 25,
          source: 'booster',
          onComplete: () {
            tracker.markClicked(l.id);
            GoalProgressPersistenceService.instance.markCompleted(
              l.id,
              DateTime.now(),
            );
          },
        ),
      );
    }
    return goals;
  }
}

class _Candidate {
  final TheoryMiniLessonNode lesson;
  final double score;
  _Candidate(this.lesson, this.score);
}
