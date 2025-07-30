import 'package:uuid/uuid.dart';

import '../../../models/v2/training_pack_spot.dart';
import '../../../models/v2/training_spot_v2.dart';
import '../../../models/v2/hand_data.dart';
import '../../../models/v2/hero_position.dart';
import '../../../models/game_type.dart';
import '../../../models/action_entry.dart';
import '../../../services/pack_generator_service.dart';

class SpotFactoryLevel2Engine {
  final Uuid _uuid;
  const SpotFactoryLevel2Engine({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  List<TrainingSpotV2> generate({
    required GameType gameType,
    required bool isHeroFirstIn,
    required bool include3betPush,
    required int count,
  }) {
    final spots = <TrainingSpotV2>[];
    final hands = PackGeneratorService.handRanking.take(60).toList();
    for (var i = 0; i < count; i++) {
      final hand = hands[i % hands.length];
      final heroPos = kPositionOrder[i % kPositionOrder.length];
      final villainPos = _prevPosition(heroPos);
      final stack = gameType == GameType.cash ? 100 : 20;

      final actions = <int, List<ActionEntry>>{0: []};
      final tags = <String>[];
      String description;

      if (isHeroFirstIn) {
        actions[0]!.add(ActionEntry(0, 0, 'open', amount: 2.5));
        actions[0]!.add(ActionEntry(0, 1, 'fold'));
        tags.add('open');
        description = 'Hero on ${heroPos.label}, ${stack}bb, first in';
      } else {
        actions[0]!.add(ActionEntry(0, 1, 'open', amount: 2.5));
        tags.add('vsopen');
        if (include3betPush) {
          actions[0]!.add(ActionEntry(0, 0, 'push', amount: stack.toDouble()));
          actions[0]!.add(ActionEntry(0, 1, 'fold'));
          tags.add('3betpush');
        } else {
          actions[0]!.add(ActionEntry(0, 0, 'fold'));
        }
        description =
            'Hero on ${heroPos.label}, ${stack}bb, facing open from ${villainPos.label}';
      }

      final spot = TrainingPackSpot(
        id: '${_uuid.v4()}_${i + 1}',
        title: hand,
        note: description,
        hand: HandData(
          heroCards: _firstCombo(hand),
          position: heroPos,
          heroIndex: 0,
          playerCount: 2,
          stacks: {'0': stack.toDouble(), '1': stack.toDouble()},
          actions: actions,
        ),
        tags: tags,
      );
      spots.add(spot);
    }
    return spots;
  }

  HeroPosition _prevPosition(HeroPosition pos) {
    final idx = kPositionOrder.indexOf(pos);
    if (idx <= 0) return kPositionOrder.last;
    return kPositionOrder[idx - 1];
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
