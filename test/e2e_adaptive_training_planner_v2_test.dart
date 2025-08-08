import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/adaptive_training_planner.dart';
import 'package:poker_analyzer/services/user_skill_model_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('novice quick produces ≤2 clusters booster-heavy', () async {
    const user = 'u1';
    final skills = UserSkillModelService.instance;
    await skills.recordAttempt(user, ['a'], correct: false);
    await skills.recordAttempt(user, ['b'], correct: false);
    await skills.recordAttempt(user, ['c'], correct: false);

    final planner = AdaptiveTrainingPlanner();
    final plan = await planner.plan(
      userId: user,
      durationMinutes: 15,
      audience: 'novice',
      format: 'quick',
    );
    expect(plan.clusters.length <= 2, true);
    expect(plan.mix['booster']! >= plan.mix['assessment']!, true);
  });

  test('advanced deep skews to assessments', () async {
    const user = 'u2';
    final skills = UserSkillModelService.instance;
    await skills.recordAttempt(user, ['a'], correct: false);
    await skills.recordAttempt(user, ['b'], correct: false);
    await skills.recordAttempt(user, ['c'], correct: false);

    final planner = AdaptiveTrainingPlanner();
    final plan = await planner.plan(
      userId: user,
      durationMinutes: 40,
      audience: 'advanced',
      format: 'deep',
    );
    expect(plan.clusters.length >= 2, true);
    expect(plan.mix['assessment']! >= plan.mix['booster']!, true);
  });

  test('bandit impact >1.0 tag is preferred under equal mastery/decay', () async {
    const user = 'u3';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('planner.maxTagsPerPlan', 1);
    await prefs.setDouble('bandit.alpha.$user.b', 5.0);
    await prefs.setDouble('bandit.beta.$user.b', 1.0);

    final skills = UserSkillModelService.instance;
    await skills.recordAttempt(user, ['a'], correct: false);
    await skills.recordAttempt(user, ['b'], correct: false);

    final planner = AdaptiveTrainingPlanner();
    final plan = await planner.plan(
      userId: user,
      durationMinutes: 20,
    );
    expect(plan.tagWeights.keys.single, 'b');
  });
}
