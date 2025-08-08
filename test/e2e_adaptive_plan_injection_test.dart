import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/autogen_pipeline_executor.dart';
import 'package:poker_analyzer/services/learning_path_store.dart';
import 'package:poker_analyzer/services/user_skill_model_service.dart';
import 'package:poker_analyzer/services/autogen_status_dashboard_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('planAndInjectForUser creates modules and is idempotent', () async {
    const user = 'u3';
    await UserSkillModelService.instance
        .recordAttempt(user, ['tag'], correct: false);
    await UserSkillModelService.instance
        .recordAttempt(user, ['tag'], correct: false);

    final exec = AutogenPipelineExecutor();
    await exec.planAndInjectForUser(user, durationMinutes: 40);
    final store = const LearningPathStore();
    final modules1 = await store.listModules(user);
    expect(modules1, isNotEmpty);

    final prefs = await SharedPreferences.getInstance();
    final lastRun = prefs.getString('theoryScheduler.lastRun.$user');
    expect(lastRun, isNotNull);

    final status =
        AutogenStatusDashboardService.instance.getStatus('AdaptivePlanner');
    expect(status, isNotNull);

    await exec.planAndInjectForUser(user, durationMinutes: 40);
    final modules2 = await store.listModules(user);
    expect(modules2.length, modules1.length);
  });
}

