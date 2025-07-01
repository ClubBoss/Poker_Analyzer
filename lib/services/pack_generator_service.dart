import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../models/action_entry.dart';
import '../models/game_type.dart';

class PackGeneratorService {
  static Future<TrainingPackTemplate> generatePushFoldPack({
    required String id,
    required String name,
    required int heroBbStack,
    required List<int> playerStacksBb,
    required HeroPosition heroPos,
    required List<String> heroRange,
  }) async {
    return generatePushFoldPackSync(
      id: id,
      name: name,
      heroBbStack: heroBbStack,
      playerStacksBb: playerStacksBb,
      heroPos: heroPos,
      heroRange: heroRange,
    );
  }

  static TrainingPackTemplate generatePushFoldPackSync({
    required String id,
    required String name,
    required int heroBbStack,
    required List<int> playerStacksBb,
    required HeroPosition heroPos,
    required List<String> heroRange,
  }) {
    final spots = <TrainingPackSpot>[];
    for (var i = 0; i < heroRange.length; i++) {
      final hand = heroRange[i];
      final heroCards = _firstCombo(hand);
      final actions = {
        0: [
          ActionEntry(0, 0, 'push', amount: heroBbStack.toDouble()),
          for (var j = 1; j < playerStacksBb.length; j++)
            ActionEntry(0, j, 'fold'),
        ]
      };
      final stacks = {
        for (var j = 0; j < playerStacksBb.length; j++)
          '$j': playerStacksBb[j].toDouble()
      };
      spots.add(
        TrainingPackSpot(
          id: '${id}_${i + 1}',
          title: '$hand push',
          hand: HandData(
            heroCards: heroCards,
            position: heroPos,
            heroIndex: 0,
            playerCount: playerStacksBb.length,
            stacks: stacks,
            actions: actions,
          ),
        ),
      );
    }
    return TrainingPackTemplate(
      id: id,
      name: name,
      gameType: GameType.tournament,
      spots: spots,
    );
  }

  static String _firstCombo(String hand) {
    const suits = ['h', 'd', 'c', 's'];
    if (hand.length == 2) {
      final r = hand[0];
      return '$r${suits[0]} $r${suits[1]}';
    }
    final r1 = hand[0];
    final r2 = hand[1];
    final suited = hand[2] == 's';
    if (suited) {
      return '$r1${suits[0]} $r2${suits[0]}';
    }
    return '$r1${suits[0]} $r2${suits[1]}';
  }

  static Set<String> parseRangeString(String raw) {
    return {
      for (final t in raw.split(RegExp('[,\n ]+')))
        if (t.trim().isNotEmpty) t.trim()
    };
  }

  static String serializeRange(Set<String> range) => range.join(' ');
}
