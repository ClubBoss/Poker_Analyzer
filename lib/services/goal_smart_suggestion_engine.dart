import '../models/xp_guided_goal.dart';
import '../models/theory_mini_lesson_node.dart';
import '../models/booster_lesson_status.dart';
import 'booster_lesson_status_service.dart';
import 'booster_path_history_service.dart';
import 'inbox_booster_tuner_service.dart';
import 'mini_lesson_library_service.dart';
import 'mistake_tag_insights_service.dart';
import 'goal_progress_persistence_service.dart';

/// Suggests XP goals targeting weak tags using mini boosters.
class GoalSmartSuggestionEngine {
  final MistakeTagInsightsService insights;
  final BoosterLessonStatusService status;
  final MiniLessonLibraryService library;
  final InboxBoosterTunerService tuner;

  const GoalSmartSuggestionEngine({
    this.insights = const MistakeTagInsightsService(),
    this.status = BoosterLessonStatusService.instance,
    this.library = MiniLessonLibraryService.instance,
    this.tuner = InboxBoosterTunerService.instance,
  });

  /// Generates a list of personalized XP goals.
  Future<List<XPGuidedGoal>> generateGoals({int maxGoals = 3}) async {
    if (maxGoals <= 0) return [];
    final insightList = await insights.buildInsights(sortByEvLoss: true);
    if (insightList.isEmpty) return [];

    final boost = await tuner.computeTagBoostScores();
    await library.loadAll();

    final items = <_Candidate>[];
    var rank = 0;
    for (final i in insightList.take(5)) {
      final tag = i.tag.label.toLowerCase();
      final lessons = library.findByTags([tag]);
      if (lessons.isEmpty) {
        rank++;
        continue;
      }
      final lesson = lessons.first;
      final st = await status.getStatus(lesson);
      if (st == BoosterLessonStatus.repeated ||
          st == BoosterLessonStatus.skipped) {
        rank++;
        continue;
      }
      final score = boost[tag] ?? 1.0;
      if (score < 1.2) {
        rank++;
        continue;
      }
      final priority = (5 - rank) + score;
      items.add(_Candidate(tag, lesson, priority));
      rank++;
    }

    if (items.isEmpty) return [];
    items.sort((a, b) => b.priority.compareTo(a.priority));

    final goals = <XPGuidedGoal>[];
    for (final c in items.take(maxGoals)) {
      goals.add(
        XPGuidedGoal(
          id: c.lesson.id,
          label: c.lesson.resolvedTitle,
          xp: 25,
          source: 'smart',
          onComplete: () {
            BoosterPathHistoryService.instance.markCompleted(
              c.lesson.id,
              c.tag,
            );
            GoalProgressPersistenceService.instance.markCompleted(
              c.lesson.id,
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
  final String tag;
  final TheoryMiniLessonNode lesson;
  final double priority;
  _Candidate(this.tag, this.lesson, this.priority);
}
