import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/xp_guided_goal.dart';
import 'package:poker_analyzer/services/mini_lesson_progress_tracker.dart';
import 'package:poker_analyzer/services/theory_booster_goal_completion_handler.dart';
import 'package:poker_analyzer/services/xp_goal_panel_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('completes matching goal when lesson completed', () async {
    final panel = XpGoalPanelController();
    bool completed = false;
    panel.addGoal(
      XPGuidedGoal(
        id: 'l1',
        label: 'L1',
        xp: 25,
        source: 'booster',
        onComplete: () => completed = true,
      ),
    );

    final handler = TheoryBoosterGoalCompletionHandler(
      progress: MiniLessonProgressTracker.instance,
      panel: panel,
    );

    await MiniLessonProgressTracker.instance.markCompleted('l1');
    await Future<void>.delayed(Duration.zero);

    expect(completed, isTrue);
    expect(panel.goals, isEmpty);
    handler.dispose();
  });
}
