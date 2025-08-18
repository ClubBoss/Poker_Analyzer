import 'dart:async';

import 'mini_lesson_progress_tracker.dart';
import '../models/xp_guided_goal.dart';
import 'xp_goal_panel_controller.dart';
import 'booster_cooldown_blocker_service.dart';

/// Listens for mini lesson completions and marks matching XP goals complete.
class TheoryBoosterGoalCompletionHandler {
  final MiniLessonProgressTracker tracker;
  final XpGoalPanelController panel;

  TheoryBoosterGoalCompletionHandler({
    MiniLessonProgressTracker? tracker,
    XpGoalPanelController? panel,
  }) : tracker = tracker ?? MiniLessonProgressTracker.instance,
       panel = panel ?? XpGoalPanelController.instance {
    _sub = this.tracker.onLessonCompleted.listen(_handle);
  }

  static final TheoryBoosterGoalCompletionHandler instance =
      TheoryBoosterGoalCompletionHandler();

  StreamSubscription<String>? _sub;

  void dispose() {
    _sub?.cancel();
  }

  void _handle(String lessonId) {
    final goals = List<XPGuidedGoal>.from(panel.goals);
    for (final g in goals) {
      if (g.id == lessonId) {
        g.onComplete();
        BoosterCooldownBlockerService.instance.markCompleted('goal');
        panel.removeGoal(g.id);
      }
    }
  }
}
