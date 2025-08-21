import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/autogen_pipeline_executor.dart';
import 'package:poker_analyzer/services/adaptive_plan_executor.dart';
import 'package:poker_analyzer/services/learning_path_store.dart';
import 'package:poker_analyzer/services/user_skill_model_service.dart';
import 'package:poker_analyzer/services/autogen_status_dashboard_service.dart';
import 'package:poker_analyzer/services/targeted_pack_booster_engine.dart';
import 'package:poker_analyzer/services/auto_format_selector.dart';
import 'package:poker_analyzer/services/pack_quality_gatekeeper_service.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

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
  }) => true;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'planner.budgetPaddingMins': 0});
  });

  test('second identical plan within window is idempotent-skip', () async {
    const user = 'u2';
    await UserSkillModelService.instance.recordAttempt(user, [
      'tag',
    ], correct: false);
    final tempDir = await Directory.systemTemp.createTemp('idem');
    final store = LearningPathStore(rootDir: tempDir.path);
    final planExec = AdaptivePlanExecutor(
      boosterEngine: _FakeBoosterEngine(),
      formatSelector: _FakeFormatSelector(),
      gatekeeper: const _PassGatekeeper(),
      store: store,
    );
    final pipeline = AutogenPipelineExecutor();
    await pipeline.planAndInjectForUser(
      user,
      durationMinutes: 40,
      executor: planExec,
    );
    final modules1 = await store.listModules(user);
    expect(modules1, isNotEmpty);

    await pipeline.planAndInjectForUser(
      user,
      durationMinutes: 40,
      executor: planExec,
    );
    final modules2 = await store.listModules(user);
    expect(modules2.length, modules1.length);
    final status = AutogenStatusDashboardService.instance.getStatus(
      'PathHardening',
    );
    final data = jsonDecode(status!.currentStage) as Map<String, dynamic>;
    expect(data['action'], 'skip');
    await tempDir.delete(recursive: true);
  });
}
