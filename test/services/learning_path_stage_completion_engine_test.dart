import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/services/learning_path_stage_completion_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const engine = LearningPathStageCompletionEngine();

  LearningPathTemplateV2 samplePath() => const LearningPathTemplateV2(
        id: 'p',
        title: 'Path',
        description: '',
        stages: [
          LearningPathStageModel(
            id: 's1',
            title: 'Stage 1',
            description: '',
            packId: 'pack1',
            requiredAccuracy: 0,
            minHands: 10,
          ),
          LearningPathStageModel(
            id: 's2',
            title: 'Stage 2',
            description: '',
            packId: 'pack2',
            requiredAccuracy: 0,
            minHands: 5,
          ),
        ],
      );

  test('isStageComplete checks minHands', () {
    final stage = samplePath().stages.first;
    expect(engine.isStageComplete(stage, 9), isFalse);
    expect(engine.isStageComplete(stage, 10), isTrue);
  });

  test('isPathComplete true when all stages complete', () {
    final path = samplePath();
    final done = engine.isPathComplete(path, {'pack1': 10, 'pack2': 5});
    expect(done, isTrue);
  });

  test('isPathComplete false when any stage incomplete', () {
    final path = samplePath();
    final done = engine.isPathComplete(path, {'pack1': 10, 'pack2': 4});
    expect(done, isFalse);
  });
}
