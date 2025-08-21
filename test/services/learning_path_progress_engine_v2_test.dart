import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/services/learning_path_progress_engine_v2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const engine = LearningPathProgressEngine();

  LearningPathTemplateV2 path0() => const LearningPathTemplateV2(
    id: 'p1',
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
        requiredAccuracy: 80,
        minHands: 10,
      ),
    ],
  );

  test('computeProgress 0 percent', () {
    final path = path0();
    final progress = engine.computeProgress(path, const {});
    expect(progress, 0);
    expect(engine.completedStages(path, const {}), 0);
  });

  test('computeProgress partial', () {
    final path = path0();
    final progress = engine.computeProgress(path, const {'s1'});
    expect(progress, closeTo(0.5, 0.01));
    expect(engine.completedStages(path, const {'s1'}), 1);
  });

  test('computeProgress full', () {
    final path = path0();
    final progress = engine.computeProgress(path, const {'s1', 's2'});
    expect(progress, 1);
    expect(engine.completedStages(path, const {'s1', 's2'}), 2);
  });
}
