import 'package:test/test.dart';
import 'package:poker_analyzer/services/training_pack_sampler.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

TrainingPackSpot _spot(String id, HeroPosition pos, int stack,
    {List<String>? board}) {
  final hand = HandData.fromSimpleInput('AhAs', pos, stack)
    ..board.addAll(board ?? []);
  return TrainingPackSpot(id: id, hand: hand);
}

void main() {
  test('sample limits size and preserves metadata', () {
    final spots = <TrainingPackSpot>[];
    for (int i = 0; i < 30; i++) {
      spots.add(_spot('s$i', HeroPosition.values[i % 6], 10 + i));
    }
    final pack = TrainingPackTemplateV2(
      id: 'p',
      name: 'Full',
      trainingType: TrainingType.pushFold,
      tags: ['test'],
      spots: spots,
      spotCount: spots.length,
    );
    const sampler = TrainingPackSampler();
    final sample = sampler.sample(pack, maxSpots: 10);

    expect(sample.spots.length, 10);
    expect(sample.name, pack.name);
    expect(sample.tags, pack.tags);
    expect(sample.isSampledPack, true);
  });

  test('sample includes each position when possible', () {
    final spots = <TrainingPackSpot>[];
    var idx = 0;
    for (final pos in kPositionOrder) {
      spots.add(_spot('s${idx++}', pos, 10));
      spots.add(_spot('s${idx++}', pos, 20));
    }
    final pack = TrainingPackTemplateV2(
      id: 'p2',
      name: 'Full',
      trainingType: TrainingType.pushFold,
      spots: spots,
      spotCount: spots.length,
    );
    const sampler = TrainingPackSampler();
    final sample = sampler.sample(pack, maxSpots: 6);
    final positions = {for (final s in sample.spots) s.hand.position};
    expect(positions.containsAll(kPositionOrder), true);
  });
}
