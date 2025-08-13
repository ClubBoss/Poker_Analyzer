import 'package:test/test.dart';
import 'package:collection/collection.dart';
import 'package:poker_analyzer/core/training/generation/training_spot_expander.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

void main() {
  test('expand generates variations', () {
    final spot = TrainingPackSpot(
      id: 's1',
      hand: HandData.fromSimpleInput('AhAs', HeroPosition.sb, 10)
        ..board.addAll(['Kh', 'Qd', '2c']),
    );
    const expander = TrainingSpotExpander();
    final list = expander.expand(spot);
    expect(list.length > 1, true);
    expect(list.first.id, 's1');
    final generated = list.where((s) => s.id != 's1');
    expect(generated.every((s) => s.meta['variation'] == true), true);
    final boards = generated.map((s) => s.hand.board.take(3).toList());
    expect(
        boards.any((b) => !const ListEquality().equals(b, ['Kh', 'Qd', '2c'])),
        true);
  });

  test('expandPack updates spotCount', () {
    final spot = TrainingPackSpot(
      id: 's1',
      hand: HandData.fromSimpleInput('AhAs', HeroPosition.sb, 10),
    );
    final pack = TrainingPackTemplateV2(
      id: 'p1',
      name: 'Test',
      trainingType: TrainingType.pushFold,
      spots: [spot],
    );
    const expander = TrainingSpotExpander();
    final res = expander.expandPack(pack);
    expect(res.spots.length, greaterThan(1));
    expect(res.spotCount, res.spots.length);
  });
}
