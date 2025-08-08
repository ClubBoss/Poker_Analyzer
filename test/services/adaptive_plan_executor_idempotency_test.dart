import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/services/adaptive_plan_executor.dart';
import 'package:poker_analyzer/services/learning_path_store.dart';
import 'package:poker_analyzer/services/targeted_pack_booster_engine.dart';
import 'package:poker_analyzer/services/auto_format_selector.dart';
import 'package:poker_analyzer/services/pack_quality_gatekeeper_service.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/injected_path_module.dart';

class _FakeBoosterEngine extends TargetedPackBoosterEngine {
  @override
  Future<List<TrainingPackTemplateV2>> generateClusterBoosterPacks({
    required List<SkillTagCluster> clusters,
    String triggerReason = 'cluster',
  }) async {
    final c = clusters.first;
    final id = 'boost_${c.clusterId}_${c.tags.join()}';
    return [
      TrainingPackTemplateV2(
        id: id,
        name: id,
        trainingType: TrainingType.booster,
        tags: c.tags,
        spots: [
          TrainingPackSpot(id: '${id}s', tags: c.tags, board: const ['As']),
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
  bool isQualityAcceptable(pack, {double minScore = 0.7, seedIssues = const {}}) {
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late LearningPathStore store;
  late AdaptivePlanExecutor exec;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'planner.budgetPaddingMins': 0});
    tempDir = await Directory.systemTemp.createTemp('idem');
    store = LearningPathStore(rootDir: tempDir.path);
    exec = AdaptivePlanExecutor(
      boosterEngine: _FakeBoosterEngine(),
      formatSelector: _FakeFormatSelector(),
      gatekeeper: const _PassGatekeeper(),
      store: store,
    );
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('identical plan within window is skipped', () async {
    final cluster =
        SkillTagCluster(tags: ['a'], clusterId: 'c1', themeName: 'T');
    final plan = AdaptivePlan(
      clusters: [cluster],
      estMins: 0,
      tagWeights: const {'a': 1.0},
    );
    final first = await exec.execute(
      userId: 'u1',
      plan: plan,
      budgetMinutes: 20,
    );
    expect(first, hasLength(1));
    final second = await exec.execute(
      userId: 'u1',
      plan: plan,
      budgetMinutes: 20,
    );
    expect(second, isEmpty);
  });

  test('creates module when tags change or window elapsed', () async {
    final cluster =
        SkillTagCluster(tags: ['a'], clusterId: 'c1', themeName: 'T');
    final plan = AdaptivePlan(
      clusters: [cluster],
      estMins: 0,
      tagWeights: const {'a': 1.0},
    );
    await exec.execute(userId: 'u1', plan: plan, budgetMinutes: 20);
    final changed = AdaptivePlan(
      clusters: [
        SkillTagCluster(tags: ['a', 'b'], clusterId: 'c1', themeName: 'T')
      ],
      estMins: 0,
      tagWeights: const {'a': 1.0, 'b': 1.0},
    );
    final res1 = await exec.execute(
      userId: 'u1',
      plan: changed,
      budgetMinutes: 20,
    );
    expect(res1, hasLength(1));

    var modules = await store.listModules('u1');
    final aged = modules
        .map((m) => InjectedPathModule(
              moduleId: m.moduleId,
              clusterId: m.clusterId,
              themeName: m.themeName,
              theoryIds: m.theoryIds,
              boosterPackIds: m.boosterPackIds,
              assessmentPackId: m.assessmentPackId,
              createdAt: m.createdAt.subtract(const Duration(days: 15)),
              triggerReason: m.triggerReason,
              status: m.status,
              metrics: m.metrics,
              itemsDurations: m.itemsDurations,
            ))
        .toList();
    for (final m in modules) {
      await store.removeModule('u1', m.moduleId);
    }
    for (final m in aged) {
      await store.upsertModule('u1', m);
    }
    final res2 = await exec.execute(
      userId: 'u1',
      plan: plan,
      budgetMinutes: 20,
    );
    expect(res2, hasLength(1));
  });
}
