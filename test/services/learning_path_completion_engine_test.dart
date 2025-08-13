import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/models/session_log.dart';
import 'package:poker_analyzer/services/learning_path_completion_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const engine = LearningPathCompletionEngine();

  LearningPathTemplateV2 path0() => const LearningPathTemplateV2(
        id: 'p',
        title: 'Path',
        description: '',
        stages: [
          LearningPathStageModel(
            id: 's1',
            title: 'Stage 1',
            description: '',
            packId: 'pack1',
            requiredAccuracy: 80,
            minHands: 10,
          ),
          LearningPathStageModel(
            id: 's2',
            title: 'Stage 2',
            description: '',
            packId: 'pack2',
            requiredAccuracy: 70,
            minHands: 5,
          ),
        ],
      );

  Map<String, SessionLog> logs0(int c1, int m1, int c2, int m2) => {
        'pack1': SessionLog(
          tags: const [],
          sessionId: 'l1',
          templateId: 'pack1',
          startedAt: DateTime.now(),
          completedAt: DateTime.now(),
          correctCount: c1,
          mistakeCount: m1,
        ),
        'pack2': SessionLog(
          tags: const [],
          sessionId: 'l2',
          templateId: 'pack2',
          startedAt: DateTime.now(),
          completedAt: DateTime.now(),
          correctCount: c2,
          mistakeCount: m2,
        ),
      };

  test('isCompleted true when all stages meet requirements', () {
    final path = path0();
    final logs = logs0(8, 2, 4, 1);
    final ok = engine.isCompleted(path, logs);
    expect(ok, isTrue);
  });

  test('isCompleted false when hands below requirement', () {
    final path = path0();
    final logs = logs0(8, 2, 3, 1); // second stage only 4 hands
    final ok = engine.isCompleted(path, logs);
    expect(ok, isFalse);
  });

  test('isCompleted false when accuracy below requirement', () {
    final path = path0();
    final logs = logs0(5, 5, 4, 1); // first stage accuracy 50%
    final ok = engine.isCompleted(path, logs);
    expect(ok, isFalse);
  });
}
