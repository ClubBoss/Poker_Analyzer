import 'package:test/test.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

void main() {
  test('dynamicParams handGroupTags expand into handGroup', () {
    final tpl = TrainingPackTemplateV2(
      id: 'id',
      name: 'name',
      trainingType: TrainingType.pushFold,
      meta: {
        'dynamicParams': {
          'handGroupTags': ['pockets'],
          'count': 1,
        },
      },
    );
    final spots = tpl.generateDynamicSpotSamples();
    expect(spots.length, 1);
  });
}
