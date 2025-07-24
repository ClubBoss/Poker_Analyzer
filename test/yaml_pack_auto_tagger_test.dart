import 'package:test/test.dart';
import 'package:poker_analyzer/services/yaml_pack_auto_tagger.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

void main() {
  test('generateTags adds category and position', () {
    final tpl = TrainingPackTemplateV2(
      id: 'x',
      name: 'Push SB',
      category: 'Push/Fold',
      positions: ['sb'],
      trainingType: TrainingType.pushFold,
    );
    const tagger = YamlPackAutoTagger();
    final tags = tagger.generateTags(tpl);
    expect(tags.contains('cat:Push/Fold'), true);
    expect(tags.contains('position:sb'), true);
    expect(tags.contains('pushfold'), true);
  });
}
