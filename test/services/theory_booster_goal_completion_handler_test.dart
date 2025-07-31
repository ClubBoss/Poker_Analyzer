import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/theory_booster_goal_completion_handler.dart';
import 'package:poker_analyzer/services/mini_lesson_progress_tracker.dart';
import 'package:poker_analyzer/services/xp_goal_panel_controller.dart';
import 'package:poker_analyzer/models/xp_guided_goal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    XpGoalPanelController.instance.clear();
    MiniLessonProgressTracker.instance.onLessonCompleted.listen((_) {});
  });

  test('marks matching goal complete and removes from panel', () async {
    var completed = 0;
    final goal = XPGuidedGoal(
      id: 'l1',
      label: 'Goal',
      xp: 25,
      source: 'booster',
      onComplete: () => completed++,
    );
    XpGoalPanelController.instance.addGoal(goal);

    final handler = TheoryBoosterGoalCompletionHandler(
      tracker: MiniLessonProgressTracker.instance,
      panel: XpGoalPanelController.instance,
    );

    await MiniLessonProgressTracker.instance.markCompleted('l1');
    await Future.delayed(Duration.zero);

    expect(completed, 1);
    expect(XpGoalPanelController.instance.goals, isEmpty);
    handler.dispose();
  });
}
