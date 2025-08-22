@TestOn('vm')
import 'package:test/test.dart';
// Замените на ваш YAML-парсер спотов в v2 (без UI)
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/utils/yaml_utils.dart'; // если у вас так называется

const _yaml = '''
id: t_pack_2
name: Simple
level: beginner
type: theory
tags: [preflop]
spots: []
''';

void main() {
  test('YAML → model → JSON (smoke)', () {
    final map = parseYamlToMap(_yaml); // функция парсинга YAML → Map
    final model = TrainingPackTemplateV2.fromJson(map);
    expect(model.id, 't_pack_2');
    expect(model.tags, contains('preflop'));
    expect(model.spots, isEmpty);
  });
}
