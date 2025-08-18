import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/theory_link_auto_injector.dart';
import 'package:poker_analyzer/services/theory_library_index.dart';
import 'package:poker_analyzer/services/learning_path_store.dart';
import 'package:poker_analyzer/services/mistake_telemetry_store.dart';
import 'package:poker_analyzer/services/theory_novelty_registry.dart';
import 'package:poker_analyzer/services/decay_tag_retention_tracker_service.dart';
import 'package:poker_analyzer/models/injected_path_module.dart';
import 'package:poker_analyzer/core/training/library/training_pack_library_v2.dart';
import 'package:poker_analyzer/services/theory_link_policy_engine.dart';
import 'package:poker_analyzer/services/theory_link_config_service.dart';

class _FakeBundle extends CachingAssetBundle {
  final String data;
  _FakeBundle(this.data);
  @override
  Future<String> loadString(String key, {bool cache = true}) async => data;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('items with higher decay rank earlier', () async {
    final dir = Directory('test_cache_decay');
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }

    SharedPreferences.setMockInitialValues({
      'telemetry.errors.x': 0.1,
      'telemetry.errors.y': 0.1,
      'theory.maxPerModule': 1,
    });
    final prefs = await SharedPreferences.getInstance();
    await TheoryLinkConfigService.instance.reload();
    final policy = TheoryLinkPolicyEngine(prefs: prefs);

    final retention = DecayTagRetentionTrackerService();
    await retention.markTheoryReviewed(
      'x',
      time: DateTime.now().subtract(const Duration(days: 30)),
    );
    await retention.markTheoryReviewed(
      'y',
      time: DateTime.now().subtract(const Duration(days: 1)),
    );

    final bundle = _FakeBundle(
      '[{"id":"th_x","title":"X","uri":"x","tags":["x"]},'
      '{"id":"th_y","title":"Y","uri":"y","tags":["y"]}]',
    );

    final store = LearningPathStore(rootDir: 'test_cache_decay/path');
    final module = InjectedPathModule(
      moduleId: 'm1',
      clusterId: 'c1',
      themeName: 't',
      theoryIds: const [],
      boosterPackIds: const [],
      assessmentPackId: '',
      createdAt: DateTime.now(),
      triggerReason: 'test',
      itemsDurations: const {},
      metrics: const {
        'clusterTags': ['x', 'y'],
      },
    );
    await store.upsertModule('u1', module);

    final packLibrary = TrainingPackLibraryV2.instance;
    packLibrary.clear();

    final injector = TheoryLinkAutoInjector(
      store: store,
      libraryIndex: TheoryLibraryIndex(assetPath: 'unused', bundle: bundle),
      telemetry: MistakeTelemetryStore(),
      noveltyRegistry: TheoryNoveltyRegistry(
        path: 'test_cache_decay/novelty.json',
      ),
      retention: retention,
      packLibrary: packLibrary,
      policy: policy,
    );

    final count = await injector.injectForUser('u1');
    expect(count, 1);

    final modules = await store.listModules('u1');
    expect(modules.first.theoryIds, ['th_x']);
  });
}
