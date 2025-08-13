import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/core/training/generation/learning_path_stage_template_generator.dart';
import 'package:poker_analyzer/core/training/generation/yaml_reader.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate stage with subStages', () {
    final generator = LearningPathStageTemplateGenerator();
    final yaml = generator.generateStageYaml(
      id: 's1',
      title: 'Stage',
      packId: 'test_pack',
      subStages: const [
        SubStageTemplateInput(
            id: 'a',
            packId: 'a',
            title: 'A',
            description: 'desc A',
            minHands: 5,
            requiredAccuracy: 60),
        SubStageTemplateInput(
          id: 'b',
          packId: 'b',
          title: 'B',
          description: 'desc B',
          minHands: 5,
          requiredAccuracy: 70,
          unlockCondition: UnlockConditionInput(dependsOn: 'a'),
        ),
      ],
    );
    final map = const YamlReader().read(yaml);
    final stage =
        LearningPathStageModel.fromJson(Map<String, dynamic>.from(map));
    expect(stage.id, 's1');
    expect(stage.subStages.length, 2);
    expect(stage.subStages.first.packId, 'a');
    expect(stage.subStages.last.unlockCondition?.dependsOn, 'a');
  });

  test('order and unlockAfter auto increment', () {
    final generator = LearningPathStageTemplateGenerator();
    final first = generator.generateStageYaml(
      id: 'first',
      title: 'First',
      packId: 'pack1',
    );
    final second = generator.generateStageYaml(
      id: 'second',
      title: 'Second',
      packId: 'pack1',
    );
    final mapFirst = const YamlReader().read(first);
    final stageFirst =
        LearningPathStageModel.fromJson(Map<String, dynamic>.from(mapFirst));
    final mapSecond = const YamlReader().read(second);
    final stageSecond =
        LearningPathStageModel.fromJson(Map<String, dynamic>.from(mapSecond));
    expect(stageFirst.order, 1);
    expect(stageSecond.order, 2);
    expect(stageSecond.unlockAfter, contains('first'));
  });
}
