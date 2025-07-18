import 'package:test/test.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/generation/yaml_reader.dart';

void main() {
  test('toYamlString adds meta.trainingType', () {
    final tpl = TrainingPackTemplateV2(
      id: 't',
      name: 'Test',
      trainingType: TrainingType.pushFold,
    );

    final yaml = tpl.toYamlString();
    final map = const YamlReader().read(yaml);

    expect(map['meta']['trainingType'], 'pushFold');
  });
}
