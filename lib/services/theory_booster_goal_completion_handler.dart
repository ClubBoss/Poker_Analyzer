import 'dart:async';

import '../models/xp_guided_goal.dart';
import 'mini_lesson_progress_tracker.dart';
import 'xp_goal_panel_controller.dart';

/// Listens to mini lesson completions and resolves matching XP goals.
class TheoryBoosterGoalCompletionHandler {
  final MiniLessonProgressTracker tracker;
  final XpGoalPanelController panel;

  TheoryBoosterGoalCompletionHandler({
    MiniLessonProgressTracker? tracker,
    XpGoalPanelController? panel,
  })  : tracker = tracker ?? MiniLessonProgressTracker.instance,
        panel = panel ?? XpGoalPanelController.instance {
    _sub = this.tracker.onLessonCompleted.listen(_handle);
  }

  static final TheoryBoosterGoalCompletionHandler instance =
      TheoryBoosterGoalCompletionHandler();

  StreamSubscription<String>? _sub;

  /// Releases stream subscription resources.
  void dispose() {
    _sub?.cancel();
  }

  void _handle(String lessonId) {
    final goals = List<XPGuidedGoal>.from(panel.goals);
    for (final g in goals) {
      if (g.id == lessonId) {
        g.onComplete();
        panel.removeGoal(lessonId);
      }
    }
  }
}
