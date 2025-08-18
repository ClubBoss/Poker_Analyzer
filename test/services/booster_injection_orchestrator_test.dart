import 'package:flutter_test/flutter_test.dart';
import 'package:collection/collection.dart';

import 'package:poker_analyzer/services/booster_injection_orchestrator.dart';
import 'package:poker_analyzer/services/booster_inventory_service.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';
import 'package:poker_analyzer/services/skill_gap_detector_service.dart';
import 'package:poker_analyzer/services/smart_booster_recall_engine.dart';
import 'package:poker_analyzer/services/learning_path_stage_library.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/booster_completion_tracker.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/services/path_map_engine.dart';

class _FakeMastery extends TagMasteryService {
  final Map<String, double> map;
  _FakeMastery(this.map)
    : super(logs: SessionLogService(sessions: TrainingSessionService()));
  @override
  Future<Map<String, double>> computeMastery({bool force = false}) async => map;
}

class _FakeInventory extends BoosterInventoryService {
  final List<TrainingPackTemplateV2> items;
  _FakeInventory(this.items);

  @override
  Future<void> loadAll({int limit = 500}) async {}

  @override
  List<TrainingPackTemplateV2> findByTag(String tag) => [
    for (final b in items)
      if (b.tags.contains(tag)) b,
  ];

  @override
  TrainingPackTemplateV2? getById(String id) =>
      items.firstWhereOrNull((b) => b.id == id);

  @override
  List<TrainingPackTemplateV2> get all => items;
}

class _FakeGapDetector extends SkillGapDetectorService {
  final List<String> tags;
  _FakeGapDetector(this.tags);
  @override
  Future<List<String>> getMissingTags({double threshold = 0.1}) async => tags;
}

class _FakeRecall extends SmartBoosterRecallEngine {
  final List<String> types;
  _FakeRecall(this.types) : super();
  @override
  Future<List<String>> getRecallableTypes(DateTime now) async => types;
}

TrainingPackTemplateV2 _pack(String id, String tag) {
  return TrainingPackTemplateV2(
    id: id,
    name: id,
    description: '',
    trainingType: TrainingType.pushFold,
    gameType: GameType.tournament,
    tags: [tag],
    spots: const [],
    spotCount: 0,
    created: DateTime.now(),
    positions: const [],
    meta: const {'type': 'booster', 'tag': tag},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    BoosterCompletionTracker.instance.resetForTest();
    LearningPathStageLibrary.instance.clear();
    LearningPathStageLibrary.instance.add(
      const LearningPathStageModel(
        id: 's1',
        title: 's1',
        description: '',
        packId: 'p1',
        requiredAccuracy: 0,
        minHands: 0,
        tags: ['push', 'call'],
      ),
    );
  });

  test('returns boosters matching weak tags', () async {
    final orch = BoosterInjectionOrchestrator(
      mastery: _FakeMastery({'push': 0.4}),
      inventory: _FakeInventory([_pack('b1', 'push'), _pack('b2', 'call')]),
      gaps: _FakeGapDetector([]),
      recall: _FakeRecall([]),
    );
    final blocks = await orch.getInjectableBoosters(
      const TrainingStageNode(id: 's1'),
    );
    expect(blocks.length, 1);
    expect(blocks.first.id, 'b1');
  });

  test('prioritizes recallable types', () async {
    final orch = BoosterInjectionOrchestrator(
      mastery: _FakeMastery({'push': 0.8}),
      inventory: _FakeInventory([_pack('b1', 'push'), _pack('b2', 'call')]),
      gaps: _FakeGapDetector([]),
      recall: _FakeRecall(['call']),
    );
    final blocks = await orch.getInjectableBoosters(
      const TrainingStageNode(id: 's1'),
    );
    expect(blocks.length, 1);
    expect(blocks.first.id, 'b2');
  });

  test('avoids duplicates in same session', () async {
    final orch = BoosterInjectionOrchestrator(
      mastery: _FakeMastery({'push': 0.4}),
      inventory: _FakeInventory([_pack('b1', 'push')]),
      gaps: _FakeGapDetector([]),
      recall: _FakeRecall([]),
    );
    final first = await orch.getInjectableBoosters(
      const TrainingStageNode(id: 's1'),
    );
    final second = await orch.getInjectableBoosters(
      const TrainingStageNode(id: 's1'),
    );
    expect(first.length, 1);
    expect(second, isEmpty);
  });

  test('skips completed boosters', () async {
    final orch = BoosterInjectionOrchestrator(
      mastery: _FakeMastery({'push': 0.4}),
      inventory: _FakeInventory([_pack('b1', 'push')]),
      gaps: _FakeGapDetector([]),
      recall: _FakeRecall([]),
    );
    await BoosterCompletionTracker.instance.markBoosterCompleted('b1');
    final blocks = await orch.getInjectableBoosters(
      const TrainingStageNode(id: 's1'),
    );
    expect(blocks, isEmpty);
  });
}
