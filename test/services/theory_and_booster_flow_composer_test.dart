import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_path_block.dart';
import 'package:poker_analyzer/services/theory_and_booster_flow_composer.dart';
import 'package:poker_analyzer/services/injection_block_assembler.dart';
import 'package:poker_analyzer/services/smart_theory_injection_engine.dart';
import 'package:poker_analyzer/services/booster_injection_orchestrator.dart';
import 'package:poker_analyzer/services/learning_path_stage_library.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/stage_type.dart';
import 'package:poker_analyzer/services/path_map_engine.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';
import 'package:poker_analyzer/services/booster_inventory_service.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';

class _FakeTheory extends SmartTheoryInjectionEngine {
  final TheoryMiniLessonNode? lesson;
  const _FakeTheory(this.lesson);

  @override
  Future<TheoryMiniLessonNode?> getInjectionCandidate(String stageId) async =>
      lesson;
}

class _FakeOrch extends BoosterInjectionOrchestrator {
  final List<LearningPathBlock> blocks;
  _FakeOrch(this.blocks)
      : super(
          mastery: TagMasteryService(
            logs: SessionLogService(sessions: TrainingSessionService()),
          ),
          inventory: BoosterInventoryService(),
        );

  @override
  Future<List<LearningPathBlock>> getInjectableBoosters(
    StageNode stage,
  ) async =>
      blocks;
}

LearningPathBlock _booster(String id) {
  return LearningPathBlock(
    id: id,
    header: id,
    content: '',
    ctaLabel: 'Start',
    lessonId: id,
    injectedInStageId: 's1',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LearningPathStageLibrary.instance.clear();
    LearningPathStageLibrary.instance.add(
      const LearningPathStageModel(
        id: 's1',
        title: 's1',
        description: '',
        packId: 'p1',
        requiredAccuracy: 0,
        minHands: 0,
        tags: ['x'],
        type: StageType.practice,
      ),
    );
  });

  test('theory first then boosters', () async {
    const lesson = TheoryMiniLessonNode(id: 't1', title: 't', content: 'c');
    final composer = TheoryAndBoosterFlowComposer(
      theoryEngine: const _FakeTheory(lesson),
      boosterOrchestrator: _FakeOrch([_booster('b1'), _booster('b2')]),
      assembler: const InjectionBlockAssembler(),
    );
    final blocks = await composer.buildStageFlow(
      const TrainingStageNode(id: 's1'),
    );
    expect(blocks.length, 3);
    expect(blocks.first.id, 't1');
    expect(blocks[1].id, 'b1');
    expect(blocks[2].id, 'b2');
  });

  test('limits boosters to two', () async {
    final composer = TheoryAndBoosterFlowComposer(
      theoryEngine: const _FakeTheory(null),
      boosterOrchestrator: _FakeOrch([
        _booster('b1'),
        _booster('b2'),
        _booster('b3'),
      ]),
      assembler: const InjectionBlockAssembler(),
    );
    final blocks = await composer.buildStageFlow(
      const TrainingStageNode(id: 's1'),
    );
    expect(blocks.length, 2);
    expect(blocks[0].id, 'b1');
    expect(blocks[1].id, 'b2');
  });

  test('returns empty when none available', () async {
    final composer = TheoryAndBoosterFlowComposer(
      theoryEngine: const _FakeTheory(null),
      boosterOrchestrator: _FakeOrch([]),
      assembler: const InjectionBlockAssembler(),
    );
    final blocks = await composer.buildStageFlow(
      const TrainingStageNode(id: 's1'),
    );
    expect(blocks, isEmpty);
  });
}
