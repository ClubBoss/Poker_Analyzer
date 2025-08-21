import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/autogen_pipeline_executor.dart';
import 'package:poker_analyzer/services/adaptive_plan_executor.dart';
import 'package:poker_analyzer/services/adaptive_training_planner.dart';
import 'package:poker_analyzer/services/learning_path_store.dart';
import 'package:poker_analyzer/services/user_skill_model_service.dart';
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
  bool isQualityAcceptable(
    pack, {
    double minScore = 0.7,
    seedIssues = const {},
  }) =>
      true;
}

class _FailingExecutor extends AdaptivePlanExecutor {
  _FailingExecutor({required LearningPathStore store})
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
    final modules = await super.execute(
      userId: userId,
      plan: plan,
      budgetMinutes: budgetMinutes,
      sig: sig,
    );
    throw Exception('fail');
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'planner.budgetPaddingMins': 0});
  });

  test('rollback removes partial modules and retry succeeds', () async {
    const user = 'u1';
    await UserSkillModelService.instance.recordAttempt(
        user,
        [
          'tag',
        ],
        correct: false);
    final tempDir = await Directory.systemTemp.createTemp('rollback');
    final store = LearningPathStore(rootDir: tempDir.path);
    final failingExec = _FailingExecutor(store: store);
    final exec = AutogenPipelineExecutor();
    bool threw = false;
    try {
      await exec.planAndInjectForUser(
        user,
        durationMinutes: 40,
        executor: failingExec,
      );
    } catch (_) {
      threw = true;
    }
    expect(threw, isTrue);
    final modulesAfter = await store.listModules(user);
    expect(modulesAfter, isEmpty);

    final okExec = AdaptivePlanExecutor(
      boosterEngine: _FakeBoosterEngine(),
      formatSelector: _FakeFormatSelector(),
      gatekeeper: const _PassGatekeeper(),
      store: store,
    );
    await exec.planAndInjectForUser(
      user,
      durationMinutes: 40,
      executor: okExec,
    );
    final modules2 = await store.listModules(user);
    expect(modules2, isNotEmpty);
    await tempDir.delete(recursive: true);
  });
}
