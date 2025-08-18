import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/auto_skill_gap_clusterer.dart';
import 'package:poker_analyzer/services/path_injection_engine.dart';
import 'package:poker_analyzer/services/learning_path_store.dart';
import 'package:poker_analyzer/services/assessment_pack_synthesizer.dart';
import 'package:poker_analyzer/services/path_registry.dart';
import 'package:poker_analyzer/services/targeted_pack_booster_engine.dart';
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

  group('PathInjectionEngine', () {
    late Directory tempDir;
    late PathRegistry registry;
    late LearningPathStore store;
    late PathInjectionEngine engine;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('registry');
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
        'path.inject.recentHours': 72,
        'path.inject.maxPerWeek': 3,
        'path.inject.maxActive': 2,
        'path.store.enabled': true,
        'path.inject.assessmentSize': 6,
      });
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('injects module for eligible cluster', () async {
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
      final m = modules.first;
      expect(m.boosterPackIds, contains('boost_c1'));
      final count = await registry.countSince(
        'u1',
        DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(count, 1);
    });

    test('respects recency limit', () async {
      final cluster = SkillTagCluster(
        tags: ['a'],
        clusterId: 'c1',
        themeName: 'Theme',
      );
      await registry.record('u1', cluster.tags);
      final decision = await engine.evaluateOpportunity(cluster, 'u1');
      expect(decision.shouldInject, isFalse);
      expect(decision.reason, 'recent_duplicate');
    });
  });
}
