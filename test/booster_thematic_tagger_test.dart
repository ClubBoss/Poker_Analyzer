import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/booster_thematic_tagger.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

TrainingPackSpot _spot({
  required String id,
  HeroPosition pos = HeroPosition.btn,
  String villain = 'open 2',
  List<String> heroOpts = const ['call', 'fold'],
}) {
  return TrainingPackSpot(
    id: id,
    villainAction: villain,
    heroOptions: heroOpts,
    hand: HandData(position: pos, playerCount: 2, stacks: {'0': 20, '1': 20}),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('detects UTG Open tag', () {
    final pack = TrainingPackTemplateV2(
      id: 'p1',
      name: 'Test',
      trainingType: TrainingType.pushFold,
      spots: [
        _spot(
          id: 's1',
          pos: HeroPosition.utg,
          villain: 'none',
          heroOpts: ['open', 'fold'],
        ),
      ],
      positions: ['utg'],
      bb: 20,
    );

    final tags = const BoosterThematicTagger().suggestThematicTags(pack);
    expect(tags, contains('UTG Open'));
  });

  test('detects SB vs BB tag', () {
    final pack = TrainingPackTemplateV2(
      id: 'p2',
      name: 'Test',
      trainingType: TrainingType.pushFold,
      spots: [_spot(id: 's1', pos: HeroPosition.bb)],
      positions: ['sb', 'bb'],
      bb: 20,
    );

    final tags = const BoosterThematicTagger().suggestThematicTags(pack);
    expect(tags, contains('SB vs BB'));
  });

  test('detects Limped Pot tag', () {
    final pack = TrainingPackTemplateV2(
      id: 'p3',
      name: 'Test',
      trainingType: TrainingType.pushFold,
      spots: [
        _spot(id: 's1', villain: 'limp', heroOpts: ['push', 'fold']),
      ],
    );
    final tags = const BoosterThematicTagger().suggestThematicTags(pack);
    expect(tags, contains('Limped Pot'));
  });
}
