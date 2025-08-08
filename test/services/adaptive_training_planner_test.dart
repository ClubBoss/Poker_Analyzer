import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/adaptive_training_planner.dart';
import 'package:poker_analyzer/services/user_skill_model_service.dart';
import 'package:poker_analyzer/services/decay_tag_retention_tracker_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('selects high score tags under budget respecting maxTagsPerPlan', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('planner.maxTagsPerPlan', 2);
    await prefs.setInt('planner.budgetPaddingMins', 5);
    await prefs.setDouble('planner.impact.a', 2.0);
    await prefs.setDouble('planner.impact.c', 0.5);

    const user = 'u1';
    final skills = UserSkillModelService.instance;
    await skills.recordAttempt(user, ['a'], correct: false);
    await skills.recordAttempt(user, ['a'], correct: false);
    await skills.recordAttempt(user, ['b'], correct: true);
    await skills.recordAttempt(user, ['c'], correct: false);
    await skills.recordAttempt(user, ['c'], correct: false);

    final retention = const DecayTagRetentionTrackerService();
    await retention.markBoosterCompleted('b', time: DateTime.now());
    await retention.markBoosterCompleted(
        'c', time: DateTime.now().subtract(const Duration(days: 15)));

    final planner = AdaptiveTrainingPlanner();
    final plan = await planner.plan(userId: user, durationMinutes: 40);
    expect(plan.tagWeights.length, 2);
    expect(plan.tagWeights.keys, containsAll(['a', 'c']));
    expect(plan.tagWeights.keys, isNot(contains('b')));
  });
}

