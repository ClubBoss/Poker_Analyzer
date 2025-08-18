import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/auto_skill_gap_clusterer.dart';
import 'package:poker_analyzer/services/path_injection_engine.dart';
import 'package:poker_analyzer/services/path_registry.dart';
import 'package:poker_analyzer/services/targeted_pack_booster_engine.dart';
import 'package:poker_analyzer/services/learning_path_store.dart';
import 'package:poker_analyzer/services/assessment_pack_synthesizer.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

class _FakeBoosterEngine extends TargetedPackBoosterEngine {
  @override
  Future<List<TrainingPackTemplateV2>> generateClusterBoosterPacks({
    required List<SkillTagCluster> clusters,
    String triggerReason = 'cluster',
  }) async {
    return clusters
        .map(
          (c) => TrainingPackTemplateV2(
            id: 'boost_${c.clusterId}',
            name: 'Boost',
            trainingType: TrainingType.booster,
            tags: c.tags,
          ),
        )
        .toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PathInjectionEngine e2e', () {
    late Directory tempDir;
    late PathRegistry registry;
    late LearningPathStore store;
    late PathInjectionEngine engine;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pie2e');
      registry = PathRegistry(path: '${tempDir.path}/reg.json');
      store = LearningPathStore(rootDir: '${tempDir.path}/paths');
      engine = PathInjectionEngine(
        boosterEngine: _FakeBoosterEngine(),
        registry: registry,
        store: store,
        synthesizer: const AssessmentPackSynthesizer(),
      );
      SharedPreferences.setMockInitialValues({
        'path.inject.enabled': true,
        'path.store.enabled': true,
        'path.inject.recentHours': 72,
        'path.inject.maxPerWeek': 3,
        'path.inject.maxActive': 2,
        'path.inject.assessmentSize': 6,
        'path.module.completeThreshold': 0.7,
      });
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('inject, persist, lifecycle and idempotence', () async {
      final cluster = SkillTagCluster(
        tags: ['a', 'b'],
        clusterId: 'c1',
        themeName: 'Theme',
      );
      final modules = await engine.injectForClusters(
        clusters: [cluster],
        userId: 'u1',
      );
      expect(modules, hasLength(1));
      var stored = await store.listModules('u1');
      expect(stored.single.status, 'pending');
      final moduleId = stored.single.moduleId;
      await engine.onModuleStarted('u1', moduleId);
      stored = await store.listModules('u1');
      expect(stored.single.status, 'in_progress');
      await engine.onModuleCompleted('u1', moduleId, passRate: 0.8);
      stored = await store.listModules('u1');
      expect(stored.single.status, 'completed');
      final reinject = await engine.injectForClusters(
        clusters: [cluster],
        userId: 'u1',
      );
      expect(reinject, isEmpty);
      stored = await store.listModules('u1');
      expect(stored, hasLength(1));
    });
  });
}
