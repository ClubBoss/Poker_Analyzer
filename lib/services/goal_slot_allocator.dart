import '../models/xp_guided_goal.dart';
import 'mistake_tag_insights_service.dart';
import 'booster_path_history_service.dart';
import 'mini_lesson_library_service.dart';

/// Assignment describing where a short-term XP goal should appear.
class GoalSlotAssignment {
  final XPGuidedGoal goal;
  final String slot; // 'home', 'theory', or 'postrecap'

  GoalSlotAssignment({required this.goal, required this.slot});
}

/// Routes XP goals to delivery slots based on urgency and context.
class GoalSlotAllocator {
  final MistakeTagInsightsService insights;
  final BoosterPathHistoryService history;
  final MiniLessonLibraryService library;

  GoalSlotAllocator({
    this.insights = const MistakeTagInsightsService(),
    BoosterPathHistoryService? history,
    MiniLessonLibraryService? library,
  }) : history = history ?? BoosterPathHistoryService.instance,
       library = library ?? MiniLessonLibraryService.instance;

  static final GoalSlotAllocator instance = GoalSlotAllocator();

  /// Returns slot assignments for each [goal].
  Future<List<GoalSlotAssignment>> allocate(List<XPGuidedGoal> goals) async {
    if (goals.isEmpty) return [];

    await library.loadAll();
    final weak = await insights.buildInsights(sortByEvLoss: true);
    final topWeak = <String>{
      for (final i in weak.take(3)) i.tag.label.toLowerCase(),
    };
    final hist = await history.getTagStats();

    final result = <GoalSlotAssignment>[];
    for (final g in goals) {
      final lesson = library.getById(g.id);
      final tag = lesson != null && lesson.tags.isNotEmpty
          ? lesson.tags.first.toLowerCase()
          : '';
      var slot = 'theory';
      if (g.source == 'smart' && topWeak.contains(tag)) {
        slot = 'home';
      } else {
        final h = hist[tag];
        if (h != null &&
            DateTime.now().difference(h.lastInteraction) <
                Duration(hours: 1)) {
          slot = 'postrecap';
        }
      }
      result.add(GoalSlotAssignment(goal: g, slot: slot));
    }
    return result;
  }
}
