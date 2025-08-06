import 'package:test/test.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/services/training_pack_template_metadata_validator.dart';

TrainingPackTemplateV2 _buildTemplate({
  Map<String, dynamic>? meta,
  List<String>? tags,
  List<TrainingPackSpot>? spots,
  int? spotCount,
}) {
  return TrainingPackTemplateV2(
    id: 'tpl',
    name: 'Test',
    trainingType: TrainingType.pushFold,
    meta: meta,
    tags: tags,
    spots: spots,
    spotCount: spotCount ?? spots?.length ?? 0,
  );
}

TrainingPackSpot _spot({String? id, String? cards, List<String>? heroOptions}) {
  return TrainingPackSpot(
    id: id ?? 's1',
    hand: HandData(heroCards: cards ?? 'As Ks'),
    heroOptions: heroOptions ?? const ['call', 'fold'],
  );
}

void main() {
  test('filters out templates missing required metadata', () {
    final valid = _buildTemplate(
      meta: {'level': 1, 'topic': 'abc'},
      tags: const ['preflop'],
      spots: [_spot()],
    );
    final missingLevel = _buildTemplate(
      meta: {'topic': 'abc'},
      tags: const ['preflop'],
      spots: [_spot()],
    );
    final missingTopic = _buildTemplate(
      meta: {'level': 1, 'topic': ''},
      tags: const ['preflop'],
      spots: [_spot()],
    );
    final badTags = _buildTemplate(
      meta: {'level': 1, 'topic': 'abc'},
      tags: const ['misc'],
      spots: [_spot()],
    );
    final spotMismatch = _buildTemplate(
      meta: {'level': 1, 'topic': 'abc'},
      tags: const ['preflop'],
      spots: [
        _spot(),
        _spot(id: 's2'),
      ],
      spotCount: 1,
    );
    final badSpot = _buildTemplate(
      meta: {'level': 1, 'topic': 'abc'},
      tags: const ['preflop'],
      spots: [_spot(id: '', cards: '', heroOptions: const [])],
    );

    final validator = const TrainingPackTemplateMetadataValidator();
    final res = validator.filter([
      valid,
      missingLevel,
      missingTopic,
      badTags,
      spotMismatch,
      badSpot,
    ]);
    expect(res.valid, [valid]);
    expect(res.rejected.length, 5);
  });
}
