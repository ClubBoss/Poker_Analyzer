import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/injected_path_module.dart';
import 'package:poker_analyzer/services/theory_link_auto_injector.dart';
import 'package:poker_analyzer/services/theory_library_index.dart';
import 'package:poker_analyzer/services/mistake_telemetry_store.dart';
import 'package:poker_analyzer/services/learning_path_store.dart';
import 'package:poker_analyzer/services/theory_novelty_registry.dart';
import 'package:poker_analyzer/services/autogen_status_dashboard_service.dart';
import 'package:poker_analyzer/core/training/library/training_pack_library_v2.dart';
import 'package:poker_analyzer/services/theory_link_policy_engine.dart';
import 'package:poker_analyzer/services/theory_link_config_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('injects theory and respects novelty and idempotency', () async {
    final cacheDir = Directory('test_cache');
    if (cacheDir.existsSync()) cacheDir.deleteSync(recursive: true);
    SharedPreferences.setMockInitialValues({
      'telemetry.errors.bb': 0.8,
      'telemetry.errors.push': 0.2,
    });
    final prefs = await SharedPreferences.getInstance();
    await TheoryLinkConfigService.instance.reload();
    final policy = TheoryLinkPolicyEngine(prefs: prefs);

    final packLibrary = TrainingPackLibraryV2.instance;
    packLibrary.clear();
    final spot = TrainingPackSpot(
      id: 's1',
      hand: HandData(),
      tags: ['push', 'bb'],
      categories: [],
    );
    final pack = TrainingPackTemplateV2(
      id: 'b1',
      name: 'Booster',
      trainingType: TrainingType.pushFold,
      spots: [spot],
      spotCount: 1,
      tags: ['push', 'bb'],
    );
    packLibrary.addPack(pack);

    final store = LearningPathStore(rootDir: 'test_cache/learning_paths');
    final module = InjectedPathModule(
      moduleId: 'm1',
      clusterId: 'c1',
      themeName: 't',
      theoryIds: const [],
      boosterPackIds: const ['b1'],
      assessmentPackId: 'b1',
      createdAt: DateTime.now(),
      triggerReason: 'test',
      itemsDurations: const {},
    );
    await store.upsertModule('u1', module);

    final registry = TheoryNoveltyRegistry(
      path: 'test_cache/theory_bundles.json',
    );
    await registry.record('u1', ['push', 'bb'], ['th_bb_def', 'th_push']);

    final injector = TheoryLinkAutoInjector(
      store: store,
      libraryIndex: TheoryLibraryIndex(),
      telemetry: MistakeTelemetryStore(),
      noveltyRegistry: registry,
      dashboard: AutogenStatusDashboardService(),
      packLibrary: packLibrary,
      policy: policy,
    );

    final injected = await injector.injectForUser('u1');
    expect(injected, 1);

    final modules = await store.listModules('u1');
    final updated = modules.first;
    expect(updated.theoryIds.contains('th_bb_def'), isTrue);
    expect(updated.theoryIds.contains('th_push'), isFalse);
    expect(updated.itemsDurations?['theoryMins'], greaterThan(0));

    final second = await injector.injectForUser('u1');
    expect(second, 0);

    expect(
      AutogenStatusDashboardService
          .instance
          .theoryClustersInjectedNotifier
          .value,
      greaterThan(0),
    );
  });
}
