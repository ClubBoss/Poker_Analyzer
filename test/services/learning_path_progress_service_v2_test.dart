import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/services/learning_path_progress_service_v2.dart';
import 'package:poker_analyzer/services/training_pack_stats_service.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const service = LearningPathProgressService();

  LearningPathTemplateV2 path() => const LearningPathTemplateV2(
        id: 'p1',
        title: 'Test Path',
        description: '',
        stages: [
          LearningPathStageModel(
            id: 's1',
            title: 'Stage 1',
            description: '',
            packId: 'pack1',
            requiredAccuracy: 80,
            minHands: 10,
            unlocks: ['s2'],
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

  final allPacks = [
    const TrainingPackTemplateV2(id: 'pack1', name: 'A'),
    const TrainingPackTemplateV2(id: 'pack2', name: 'B'),
  ];

  test('computes progress and current stage', () {
    final stats = {
      'pack1': TrainingPackStat(accuracy: 0.95, last: DateTime.now()),
      'pack2': TrainingPackStat(accuracy: 0.5, last: DateTime.now()),
    };

    final progress = service.computeProgress(
      allPacks: allPacks,
      stats: stats,
      path: path(),
    );

    expect(progress.completedStages, 1);
    expect(progress.totalStages, 2);
    expect(progress.currentStageId, 's2');
    expect(progress.overallAccuracy, closeTo(95, 0.1));
  });

  test('no completion returns first stage as current', () {
    final stats = {
      'pack1': TrainingPackStat(accuracy: 0.5, last: DateTime.now()),
    };

    final progress = service.computeProgress(
      allPacks: allPacks,
      stats: stats,
      path: path(),
    );

    expect(progress.completedStages, 0);
    expect(progress.currentStageId, 's1');
    expect(progress.overallAccuracy, 0);
  });
}
