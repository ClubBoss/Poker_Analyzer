import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/models/session_log.dart';
import 'package:poker_analyzer/services/learning_path_stage_unlock_engine.dart';
import 'package:poker_analyzer/services/learning_path_stage_ui_status_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const engine = LearningPathStageUnlockEngine();

  LearningPathTemplateV2 path0() => const LearningPathTemplateV2(
        id: 'p',
        title: 'Path',
        description: '',
        stages: [
          LearningPathStageModel(
            id: 's1',
            title: 'S1',
            description: '',
            packId: 'pack1',
            requiredAccuracy: 80,
            minHands: 2,
          ),
          LearningPathStageModel(
            id: 's2',
            title: 'S2',
            description: '',
            packId: 'pack2',
            requiredAccuracy: 70,
            minHands: 1,
          ),
          LearningPathStageModel(
            id: 's3',
            title: 'S3',
            description: '',
            packId: 'pack3',
            requiredAccuracy: 70,
            minHands: 1,
          ),
        ],
      );

  SessionLog log(String id, int correct, int mistakes) => SessionLog(
        tags: const [],
        sessionId: '1',
        templateId: id,
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        correctCount: correct,
        mistakeCount: mistakes,
      );

  test('only next stage active after completion', () {
    final path = path0();
    final logs = {'pack1': log('pack1', 2, 0)};
    final states = engine.computeStageUIStates(path, logs);
    expect(states['s1'], LearningStageUIState.done);
    expect(states['s2'], LearningStageUIState.active);
    expect(states['s3'], LearningStageUIState.locked);
  });

  test('first stage active when none completed', () {
    final path = path0();
    final states = engine.computeStageUIStates(path, const {});
    expect(states['s1'], LearningStageUIState.active);
    expect(states['s2'], LearningStageUIState.locked);
    expect(states['s3'], LearningStageUIState.locked);
  });
}
