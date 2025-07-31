import 'dart:async';

import '../models/xp_guided_goal.dart';
import 'mini_lesson_progress_tracker.dart';
import 'xp_goal_panel_controller.dart';

/// Handles completion of booster XP goals when a mini lesson is finished.
class TheoryBoosterGoalCompletionHandler {
  final MiniLessonProgressTracker progress;
  final XpGoalPanelController panel;

  TheoryBoosterGoalCompletionHandler({
    MiniLessonProgressTracker? progress,
    XpGoalPanelController? panel,
  })  : progress = progress ?? MiniLessonProgressTracker.instance,
        panel = panel ?? XpGoalPanelController.instance {
    _sub = this.progress.onLessonCompleted.listen(_handle);
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
        panel.removeGoal(lessonId);
        break;
      }
    }
  }
}
