import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/learning_path_template_builder.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/core/training/library/training_pack_library_v2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await TrainingPackLibraryV2.instance.reload();
  });

  test('fromYamlFile parses sample', () {
    final tpl = LearningPathTemplateBuilder.fromYamlFile(
      'assets/learning_paths/sample_path.yaml',
    );
    expect(tpl.id, 'sample');
    expect(tpl.stages.length, 2);
    expect(tpl.sections.length, 2);
    expect(tpl.sections.first.title, 'Push/Fold Basics');
  });

  test('checkForCycles detects simple loop', () {
    final tpl = LearningPathTemplateV2(
      id: 'cycle',
      title: 'cycle',
      description: '',
      stages: [
        LearningPathStageModel(
          id: 'a',
          title: 'a',
          description: '',
          packId: 'cbet_ip',
          requiredAccuracy: 80,
          minHands: 1,
          unlocks: ['b'],
        ),
        LearningPathStageModel(
          id: 'b',
          title: 'b',
          description: '',
          packId: 'cbet_ip',
          requiredAccuracy: 80,
          minHands: 1,
          unlocks: ['a'],
        ),
      ],
    );
    final cycle = LearningPathTemplateBuilder.checkForCycles(tpl);
    expect(cycle.isNotEmpty, true);
  });

  test('validate fails on missing pack', () {
    final tpl = LearningPathTemplateV2(
      id: 'x',
      title: 'x',
      description: '',
      stages: [
        LearningPathStageModel(
          id: 's',
          title: 's',
          description: '',
          packId: 'missing_pack',
          requiredAccuracy: 80,
          minHands: 1,
        ),
      ],
    );
    expect(
      () => LearningPathTemplateBuilder.validate(tpl),
      throwsFormatException,
    );
  });
}
