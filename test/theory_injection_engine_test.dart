import 'package:test/test.dart';
import 'package:poker_analyzer/services/theory_injection_engine.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

TrainingPackSpot _spot(String id) {
  return TrainingPackSpot(id: id, hand: HandData());
}

TrainingPackSpot _theory(String id) {
  return TrainingPackSpot(id: id, type: 'theory', hand: HandData());
}

void main() {
  const engine = TheoryInjectionEngine();

  test('injectTheory mixes theory spots at interval', () {
    final baseSpots = [_spot('a'), _spot('b'), _spot('c'), _spot('d')];
    final theorySpots = [_theory('t1'), _theory('t2')];
    final base = TrainingPackTemplateV2(
      id: 'b',
      name: 'Base',
      trainingType: TrainingType.pushFold,
      spots: baseSpots,
      spotCount: baseSpots.length,
    );
    final theory = TrainingPackTemplateV2(
      id: 't',
      name: 'Theory',
      trainingType: TrainingType.pushFold,
      spots: theorySpots,
      spotCount: theorySpots.length,
    );

    final res = engine.injectTheory(base, theory, interval: 2);
    expect(res.spotCount, 6);
    expect(res.id, base.id);
    expect(res.trainingType, base.trainingType);
    expect(
        res.spots.map((s) => s.id).toList(), ['t1', 'a', 'b', 't2', 'c', 'd']);
  });

  test('interval 1 alternates theory and practice', () {
    final baseSpots = [_spot('x'), _spot('y')];
    final theorySpots = [_theory('t1'), _theory('t2')];
    final base = TrainingPackTemplateV2(
      id: 'b2',
      name: 'Base2',
      trainingType: TrainingType.pushFold,
      spots: baseSpots,
      spotCount: baseSpots.length,
    );
    final theory = TrainingPackTemplateV2(
      id: 't2',
      name: 'Theory2',
      trainingType: TrainingType.pushFold,
      spots: theorySpots,
      spotCount: theorySpots.length,
    );

    final res = engine.injectTheory(base, theory, interval: 1);
    expect(res.spots.map((s) => s.id).toList(), ['t1', 'x', 't2', 'y']);
  });
}
