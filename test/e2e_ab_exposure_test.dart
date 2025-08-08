import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/ab_orchestrator_service.dart';
import 'package:poker_analyzer/services/adaptive_training_planner.dart';
import 'package:poker_analyzer/services/autogen_pipeline_executor.dart';
import 'package:poker_analyzer/services/autogen_pipeline_event_logger_service.dart';
import 'package:poker_analyzer/services/plan_signature_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'ab.enabled': true,
      'planner.weight.impact': 0.15,
    });
    AutogenPipelineEventLoggerService.clearLog();
    ABOrchestratorService.instance.clearCache();
  });

  test('exposure logged once per run', () async {
    final exec = AutogenPipelineExecutor();
    await exec.planAndInjectForUser('userExp', durationMinutes: 15);
    final log = AutogenPipelineEventLoggerService.getLog();
    final exposures = log.where((e) => e.type == 'ab_exposure').length;
    expect(exposures, 1);
  });

  test('overrides are scoped and signatures depend on arm', () async {
    final exec = AutogenPipelineExecutor();
    final svc = ABOrchestratorService.instance;
    final prefs = await SharedPreferences.getInstance();

    // find users for different arms
    String? hiUser;
    String? ctrlUser;
    for (var i = 0; i < 100 && (hiUser == null || ctrlUser == null); i++) {
      final uid = 'user$i';
      final arms = await svc.resolveActiveArms(uid, 'regular');
      if (arms.isEmpty) continue;
      if (arms.first.armId == 'hiImpact' && hiUser == null) hiUser = uid;
      if (arms.first.armId == 'control' && ctrlUser == null) ctrlUser = uid;
    }
    expect(hiUser, isNotNull);
    expect(ctrlUser, isNotNull);

    await exec.planAndInjectForUser(hiUser!, durationMinutes: 10);
    expect(prefs.getDouble('planner.weight.impact'), 0.15);

    await exec.planAndInjectForUser(ctrlUser!, durationMinutes: 10);
    expect(prefs.getDouble('planner.weight.impact'), 0.15);

    final arms1 = await svc.resolveActiveArms(hiUser!, 'regular');
    final arms2 = await svc.resolveActiveArms(hiUser!, 'regular');
    expect(arms1.single.armId, arms2.single.armId);

    final planner = AdaptiveTrainingPlanner();
    final abHi = arms1.map((a) => '${a.expId}:${a.armId}').join(',');
    final planHi = await planner.plan(
      userId: hiUser!,
      durationMinutes: 10,
      audience: 'regular',
      format: 'standard',
      abArm: abHi,
    );
    final sigHi = await PlanSignatureBuilder().build(
      userId: hiUser!,
      plan: planHi,
      audience: 'regular',
      format: 'standard',
      budgetMinutes: 10,
      abArm: abHi,
    );
    final armsCtrl = await svc.resolveActiveArms(ctrlUser!, 'regular');
    final abCtrl = armsCtrl.map((a) => '${a.expId}:${a.armId}').join(',');
    final planCtrl = await planner.plan(
      userId: ctrlUser!,
      durationMinutes: 10,
      audience: 'regular',
      format: 'standard',
      abArm: abCtrl,
    );
    final sigCtrl = await PlanSignatureBuilder().build(
      userId: ctrlUser!,
      plan: planCtrl,
      audience: 'regular',
      format: 'standard',
      budgetMinutes: 10,
      abArm: abCtrl,
    );
    expect(sigHi, isNot(sigCtrl));
  });
}
