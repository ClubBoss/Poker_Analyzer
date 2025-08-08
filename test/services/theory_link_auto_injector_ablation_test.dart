import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/injected_path_module.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/services/learning_path_store.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/services/mistake_telemetry_store.dart';
import 'package:poker_analyzer/services/theory_library_index.dart';
import 'package:poker_analyzer/services/theory_link_auto_injector.dart';
import 'package:poker_analyzer/services/theory_link_config_service.dart';
import 'package:poker_analyzer/services/theory_link_policy_engine.dart';
import 'package:poker_analyzer/services/theory_novelty_registry.dart';
import 'package:poker_analyzer/services/autogen_status_dashboard_service.dart';
import 'package:poker_analyzer/core/training/library/training_pack_library_v2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ablation flag disables injection', () async {
    final dir = Directory('test_cache_ablation');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    SharedPreferences.setMockInitialValues({'theory.ablation': true});
    final prefs = await SharedPreferences.getInstance();
    await TheoryLinkConfigService.instance.reload();
    final policy = TheoryLinkPolicyEngine(prefs: prefs);

    final packLibrary = TrainingPackLibraryV2.instance;
    packLibrary.clear();
    final spot = TrainingPackSpot(id: 's1', hand: HandData(), tags: ['a'], categories: []);
    final pack = TrainingPackTemplateV2(
      id: 'p1',
      name: 'Pack',
      trainingType: TrainingType.pushFold,
      spots: [spot],
      spotCount: 1,
      tags: ['a'],
    );
    packLibrary.addPack(pack);

    final store = LearningPathStore(rootDir: 'test_cache_ablation/path');
    final module = InjectedPathModule(
      moduleId: 'm1',
      clusterId: 'c1',
      themeName: 't',
      theoryIds: const [],
      boosterPackIds: const ['p1'],
      assessmentPackId: 'p1',
      createdAt: DateTime.now(),
      triggerReason: 'test',
      itemsDurations: const {},
    );
    await store.upsertModule('u1', module);

    final injector = TheoryLinkAutoInjector(
      store: store,
      libraryIndex: TheoryLibraryIndex(),
      telemetry: MistakeTelemetryStore(),
      noveltyRegistry: TheoryNoveltyRegistry(path: 'test_cache_ablation/novelty.json'),
      policy: policy,
      packLibrary: packLibrary,
      dashboard: AutogenStatusDashboardService(),
    );

    final count = await injector.injectForUser('u1');
    expect(count, 0);
    final status = AutogenStatusDashboardService.instance
        .getStatusNotifier('TheoryLinkPolicy')
        .value;
    final data = jsonDecode(status.currentStage) as Map<String, dynamic>;
    expect(data['ablation'], true);
  });
}
