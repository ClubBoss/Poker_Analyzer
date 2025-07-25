import 'package:test/test.dart';
import 'package:poker_analyzer/services/theory_pack_sampler.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

TrainingPackSpot _spot(String id, String type) {
  return TrainingPackSpot(id: id, type: type, hand: HandData());
}

void main() {
  test('sample returns null when no theory spots', () {
    final pack = TrainingPackTemplateV2(
      id: 'p1',
      name: 'Pack',
      trainingType: TrainingType.pushFold,
      spots: [_spot('a', 'quiz')],
      spotCount: 1,
    );
    const sampler = TheoryPackSampler();
    final sample = sampler.sample(pack);
    expect(sample, isNull);
  });

  test('sample extracts theory spots and updates metadata', () {
    final spots = [
      _spot('a', 'quiz'),
      _spot('b', 'theory'),
      _spot('c', 'theory'),
    ];
    final pack = TrainingPackTemplateV2(
      id: 'p2',
      name: 'Full',
      trainingType: TrainingType.pushFold,
      spots: spots,
      spotCount: spots.length,
    );
    const sampler = TheoryPackSampler();
    final sample = sampler.sample(pack);
    expect(sample, isNotNull);
    expect(sample!.spots.length, 2);
    expect(sample.id, 'p2-theory');
    expect(sample.name.startsWith('📘 Теория:'), true);
    expect(sample.isSampledPack, true);
  });
}
