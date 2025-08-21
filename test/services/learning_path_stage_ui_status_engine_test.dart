import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/services/learning_path_stage_ui_status_engine.dart';
import 'package:poker_analyzer/services/learning_path_stage_unlock_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const unlockEngine = LearningPathStageUnlockEngine();
  const uiEngine = LearningPathStageUIStatusEngine(unlockEngine: unlockEngine);

  LearningPathTemplateV2 path0() => const LearningPathTemplateV2(
        id: 'p',
        title: 'Path',
        description: '',
        stages: [
          LearningPathStageModel(
            id: 'a',
            title: 'A',
            description: '',
            packId: 'pack1',
            requiredAccuracy: 80,
            minHands: 1,
            unlocks: ['b'],
          ),
          LearningPathStageModel(
            id: 'b',
            title: 'B',
            description: '',
            packId: 'pack2',
            requiredAccuracy: 70,
            minHands: 1,
          ),
        ],
      );

  test('computeStageUIStates returns locked, active, done', () {
    final path = path0();
    final result1 = uiEngine.computeStageUIStates(path, const {});
    expect(result1['a'], LearningStageUIState.active);
    expect(result1['b'], LearningStageUIState.locked);

    final result2 = uiEngine.computeStageUIStates(path, const {'a'});
    expect(result2['a'], LearningStageUIState.done);
    expect(result2['b'], LearningStageUIState.active);
  });
}
