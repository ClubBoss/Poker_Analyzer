import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/autogen_pipeline_executor.dart';
import 'package:poker_analyzer/services/adaptive_plan_executor.dart';
import 'package:poker_analyzer/services/adaptive_training_planner.dart';
import 'package:poker_analyzer/services/learning_path_store.dart';
import 'package:poker_analyzer/services/user_skill_model_service.dart';
import 'package:poker_analyzer/services/autogen_status_dashboard_service.dart';
import 'package:poker_analyzer/services/targeted_pack_booster_engine.dart';
import 'package:poker_analyzer/services/auto_format_selector.dart';
import 'package:poker_analyzer/services/pack_quality_gatekeeper_service.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/injected_path_module.dart';

class _FakeBoosterEngine extends TargetedPackBoosterEngine {
  @override
  Future<List<TrainingPackTemplateV2>> generateClusterBoosterPacks({
    required List<SkillTagCluster> clusters,
    String triggerReason = 'cluster',
  }) async {
    final c = clusters.first;
    return [
      TrainingPackTemplateV2(
        id: 'boost_${c.clusterId}',
        name: 'Boost',
        trainingType: TrainingType.booster,
        tags: c.tags,
        spots: [
          TrainingPackSpot(id: 's1', tags: c.tags, board: const ['Ah']),
        ],
        spotCount: 4,
        meta: const {'qualityScore': 1.0},
      ),
    ];
  }
}

class _FakeFormatSelector extends AutoFormatSelector {
  @override
  FormatMeta effectiveFormat({String? audience}) =>
      const FormatMeta(spotsPerPack: 4, streets: 1, theoryRatio: 0.5);
}

class _PassGatekeeper extends PackQualityGatekeeperService {
  const _PassGatekeeper();
  @override
  bool isQualityAcceptable(pack,
          {double minScore = 0.7, seedIssues = const {}}) =>
      true;
}

class _SlowExecutor extends AdaptivePlanExecutor {
  _SlowExecutor({required LearningPathStore store})
      : super(
          boosterEngine: _FakeBoosterEngine(),
          formatSelector: _FakeFormatSelector(),
          gatekeeper: const _PassGatekeeper(),
          store: store,
        );
  @override
  Future<List<InjectedPathModule>> execute({
    required String userId,
    required AdaptivePlan plan,
    required int budgetMinutes,
    required String sig,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    return super.execute(
      userId: userId,
      plan: plan,
      budgetMinutes: budgetMinutes,
      sig: sig,
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'planner.budgetPaddingMins': 0,
      'path.lock.timeoutSec': 1,
    });
  });

  test('one run injects, other locked-skip', () async {
    const user = 'u1';
    await UserSkillModelService.instance
        .recordAttempt(user, ['tag'], correct: false);
    final tempDir = await Directory.systemTemp.createTemp('lock');
    final store = LearningPathStore(rootDir: tempDir.path);
    final exec = AutogenPipelineExecutor();
    final slow = _SlowExecutor(store: store);
    final f1 = exec.planAndInjectForUser(
      user,
      durationMinutes: 40,
      executor: slow,
    );
    await Future.delayed(const Duration(milliseconds: 100));
    await exec.planAndInjectForUser(
      user,
      durationMinutes: 40,
      executor: slow,
    );
    final status =
        AutogenStatusDashboardService.instance.getStatus('PathHardening');
    expect(status, isNotNull);
    final data = jsonDecode(status!.currentStage) as Map<String, dynamic>;
    expect(data['action'], 'locked');
    await f1;
    final modules = await store.listModules(user);
    expect(modules.length, 1);
    await tempDir.delete(recursive: true);
  });
}
