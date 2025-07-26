import 'package:test/test.dart';
import 'package:poker_analyzer/models/theory_pack_model.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/services/theory_pack_auto_indexer_service.dart';
import 'package:poker_analyzer/core/training/generation/yaml_reader.dart';

LearningPathStageModel _stage({String id = 's1', String? theoryId}) =>
    LearningPathStageModel(
      id: id,
      title: id,
      description: '',
      packId: 'p1',
      requiredAccuracy: 80,
      minHands: 10,
      tags: const ['t'],
      theoryPackId: theoryId,
    );

void main() {
  test('buildIndexYaml groups packs by usage', () {
    final longText = List.filled(150, 'word').join(' ');
    final packs = [
      TheoryPackModel(id: 't1', title: 'A', sections: [
        TheorySectionModel(title: 's', text: longText, type: 'info'),
      ]),
      TheoryPackModel(id: 't2', title: 'B', sections: const []),
    ];
    final paths = [
      LearningPathTemplateV2(
        id: 'path',
        title: 'Path',
        description: '',
        stages: [_stage(theoryId: 't1'), _stage(id: 's2', theoryId: 't3')],
      ),
    ];

    final yaml = const TheoryPackAutoIndexerService()
        .buildIndexYaml(packs, paths);

    final map = const YamlReader().read(yaml);

    expect(map['used'], isNotEmpty);
    expect(map['unused'], isNotEmpty);
    expect(map['missing'], isNotEmpty);

    expect(map['used'][0]['id'], 't1');
    expect(map['used'][0]['reviewStatus'], 'approved');
    expect(map['used'][0]['wordCount'], 150);
    expect(map['used'][0]['readTimeMinutes'], 1);
    expect(map['unused'][0]['id'], 't2');
    expect(map['unused'][0]['reviewStatus'], 'rewrite');
    expect(map['missing'][0]['id'], 't3');
  });
}
