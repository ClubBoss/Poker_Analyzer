import 'package:test/test.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';

void main() {
  test('fromJson parses metadata fields', () {
    final tpl = TrainingPackTemplateV2.fromJson({
      'id': 't',
      'name': 'Test',
      'trainingType': 'pushFold',
      'tags': ['a', 'b'],
      'goal': 'Learn',
      'audience': 'Beginners',
      'meta': {'x': 1},
    });
    expect(tpl.tags, ['a', 'b']);
    expect(tpl.category, 'a');
    expect(tpl.goal, 'Learn');
    expect(tpl.audience, 'Beginners');
    expect(tpl.meta['x'], 1);
  });

  test('category falls back to first tag', () {
    final tpl = TrainingPackTemplateV2.fromJson({
      'id': 'x',
      'name': 'X',
      'trainingType': 'pushFold',
      'tags': ['m'],
    });
    expect(tpl.category, 'm');
  });
}
