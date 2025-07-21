import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/services/learning_path_stage_unlock_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const engine = LearningPathStageUnlockEngine();

  LearningPathTemplateV2 _path() {
    return LearningPathTemplateV2(
      id: 'p',
      title: 'Path',
      description: '',
      stages: [
        const LearningPathStageModel(
          id: 'a',
          title: 'A',
          description: '',
          packId: 'pack1',
          requiredAccuracy: 80,
          minHands: 1,
          unlocks: ['b'],
        ),
        const LearningPathStageModel(
          id: 'b',
          title: 'B',
          description: '',
          packId: 'pack2',
          requiredAccuracy: 70,
          minHands: 1,
          unlocks: ['d'],
        ),
        const LearningPathStageModel(
          id: 'c',
          title: 'C',
          description: '',
          packId: 'pack3',
          requiredAccuracy: 70,
          minHands: 1,
          unlocks: ['d'],
        ),
        const LearningPathStageModel(
          id: 'd',
          title: 'D',
          description: '',
          packId: 'pack4',
          requiredAccuracy: 70,
          minHands: 1,
        ),
      ],
    );
  }

  test('root stage is unlocked', () {
    final path = _path();
    final ok = engine.isStageUnlocked(path, 'a', <String>{});
    expect(ok, isTrue);
  });

  test('single unlock dependency', () {
    final path = _path();
    expect(engine.isStageUnlocked(path, 'b', <String>{}), isFalse);
    expect(engine.isStageUnlocked(path, 'b', {'a'}), isTrue);
  });

  test('multiple unlock dependencies', () {
    final path = _path();
    expect(engine.isStageUnlocked(path, 'd', {'b'}), isFalse);
    expect(engine.isStageUnlocked(path, 'd', {'c'}), isFalse);
    expect(engine.isStageUnlocked(path, 'd', {'b', 'c'}), isTrue);
  });
}
