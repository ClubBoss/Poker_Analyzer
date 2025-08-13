import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/level_tag_auto_assigner.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';

void main() {
  const assigner = LevelTagAutoAssigner();

  TrainingPackTemplateV2 tpl0({
    List<String>? tags,
    TrainingType trainingType = TrainingType.custom,
  }) {
    return TrainingPackTemplateV2(
      id: 'id',
      name: 'name',
      tags: tags,
      trainingType: trainingType,
    );
  }

  test('assigns level 1 for pushFold training type', () {
    final tpl = tpl0(trainingType: TrainingType.pushFold);
    assigner.assign([tpl]);
    expect(tpl.meta['level'], 1);
  });

  test('assigns level 2 for open tag', () {
    final tpl = tpl0(tags: ['open']);
    assigner.assign([tpl]);
    expect(tpl.meta['level'], 2);
  });

  test('assigns level 3 for jamDecision tag', () {
    final tpl = tpl0(tags: ['jamDecision']);
    assigner.assign([tpl]);
    expect(tpl.meta['level'], 3);
  });

  test('defaults to level 0 when no rules match', () {
    final tpl = tpl0(tags: ['random']);
    assigner.assign([tpl]);
    expect(tpl.meta['level'], 0);
  });
}
