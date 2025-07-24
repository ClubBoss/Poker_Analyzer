import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/core/training/generation/learning_path_auto_pack_assigner.dart';
import 'package:poker_analyzer/core/training/generation/learning_path_stage_template_generator.dart';
import 'package:poker_analyzer/core/training/generation/learning_path_library_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const stages = [
    LearningPathStageTemplateInput(
      id: 's1',
      title: 'Stage',
      packId: 'main',
      subStages: [
        SubStageTemplateInput(
          id: 'bb10_UTG_push',
          packId: '',
          title: 'A',
          description: '',
        ),
        SubStageTemplateInput(
          id: 'other',
          packId: '',
          title: 'B',
          description: '',
        ),
      ],
    ),
  ];

  test('byPrefix strategy assigns packId', () {
    final assigner = LearningPathAutoPackAssigner();
    final result = assigner.assignPackIds(
      stages,
      const ByPrefixStrategy(prefix: 'bb10_UTG_', packId: 'bb10_UTG_main'),
    );
    expect(result.first.subStages.first.packId, 'bb10_UTG_main');
    expect(result.first.subStages.last.packId, 'other');
  });

  test('manualMap strategy assigns packId', () {
    final assigner = LearningPathAutoPackAssigner();
    final result = assigner.assignPackIds(
      stages,
      const ManualMapStrategy({'bb10_UTG_': 'bb10_UTG_main'}),
    );
    expect(result.first.subStages.first.packId, 'bb10_UTG_main');
  });
}
