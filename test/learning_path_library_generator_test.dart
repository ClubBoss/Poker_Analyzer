import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/core/training/generation/learning_path_library_generator.dart';
import 'package:poker_analyzer/core/training/generation/yaml_reader.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generatePathYaml builds stages with unlockAfter', () {
    final generator = LearningPathLibraryGenerator();
    final yaml = generator.generatePathYaml([
      const LearningPathStageTemplateInput(
        id: 's1',
        title: 'Stage 1',
        packId: 'pack1',
        tags: ['a'],
      ),
      const LearningPathStageTemplateInput(
        id: 's2',
        title: 'Stage 2',
        packId: 'pack2',
        tags: ['b'],
      ),
    ]);
    final map = const YamlReader().read(yaml);
    final stages = [
      for (final m in (map['stages'] as List? ?? []))
        LearningPathStageModel.fromJson(Map<String, dynamic>.from(m)),
    ];
    expect(stages.length, 2);
    expect(stages.first.order, 1);
    expect(stages[1].order, 2);
    expect(stages[1].unlockAfter, contains('s1'));
    final tags = List<String>.from(map['tags'] as List);
    expect(tags.contains('a'), true);
    expect(tags.contains('b'), true);
  });
}
