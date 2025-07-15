import 'package:uuid/uuid.dart';
import '../../../models/v2/training_pack_template.dart';
import '../../../models/v2/training_pack_spot.dart';
import '../../../models/v2/hand_data.dart';
import '../../../models/v2/hero_position.dart';
import '../../../models/game_type.dart';
import '../../../models/action_entry.dart';
import '../../../services/pack_generator_service.dart';
import '../../../utils/template_coverage_utils.dart';
import '../../../helpers/poker_position_helper.dart';

class PushFoldPackGenerator {
  final Uuid _uuid;
  const PushFoldPackGenerator({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  TrainingPackTemplate generate({
    required GameType gameType,
    required int bb,
    required List<String> positions,
    int count = 25,
  }) {
    final posList = positions.map(parseHeroPosition).toList();
    final availableHands = PackGeneratorService.topNHands(count).toList();
    final limit = availableHands.length < count ? availableHands.length : count;
    final hands = availableHands.take(limit).toList();
    final spots = <TrainingPackSpot>[];
    var index = 1;
    for (final pos in posList) {
      for (final hand in hands) {
        final cards = _firstCombo(hand);
        final data = HandData.fromSimpleInput(cards, pos, bb);
        spots.add(
          TrainingPackSpot(
            id: '${_uuid.v4()}_${index++}',
            title: '$hand push',
            hand: data,
            tags: const ['pushfold'],
          ),
        );
      }
    }
    final now = DateTime.now();
    final tpl = TrainingPackTemplate(
      id: _uuid.v4(),
      name: 'Push/Fold ${bb}BB',
      description: 'Auto pack ${bb}BB ${positions.join(', ')}',
      gameType: gameType,
      spots: spots,
      heroBbStack: bb,
      playerStacksBb: [bb, bb],
      heroPos: posList.isEmpty ? HeroPosition.sb : posList.first,
      spotCount: spots.length,
      anteBb: 0,
      bbCallPct: 20,
      heroRange: hands,
      createdAt: now,
      lastGeneratedAt: now,
    );
    TemplateCoverageUtils.recountAll(tpl);
    return tpl;
  }

  String _firstCombo(String hand) {
    const suits = ['h', 'd', 'c', 's'];
    if (hand.length == 2) {
      final r = hand[0];
      return '$r${suits[0]} $r${suits[1]}';
    }
    final r1 = hand[0];
    final r2 = hand[1];
    final suited = hand.length == 3 && hand[2] == 's';
    if (suited) return '$r1${suits[0]} $r2${suits[0]}';
    return '$r1${suits[0]} $r2${suits[1]}';
  }
}
