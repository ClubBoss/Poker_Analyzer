import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../models/action_entry.dart';
import '../models/game_type.dart';
import 'push_fold_ev_service.dart';

class PackGeneratorService {
  static const _ranks = [
    'A',
    'K',
    'Q',
    'J',
    'T',
    '9',
    '8',
    '7',
    '6',
    '5',
    '4',
    '3',
    '2'
  ];

  static final List<String> handRanking = (() {
    final hands = <String>[];
    for (var i = 0; i < _ranks.length; i++) {
      for (var j = 0; j < _ranks.length; j++) {
        if (i == j) {
          hands.add('${_ranks[i]}${_ranks[j]}');
        } else if (i < j) {
          hands.add('${_ranks[i]}${_ranks[j]}s');
        } else {
          hands.add('${_ranks[j]}${_ranks[i]}o');
        }
      }
    }
    int score(String h) {
      const map = {
        '2': 2,
        '3': 3,
        '4': 4,
        '5': 5,
        '6': 6,
        '7': 7,
        '8': 8,
        '9': 9,
        'T': 10,
        'J': 11,
        'Q': 12,
        'K': 13,
        'A': 14,
      };
      final r1 = map[h[0]]!;
      final r2 = map[h[1]]!;
      final suited = h.length == 3 && h[2] == 's';
      if (r1 == r2) return r1 * 20;
      final high = r1 > r2 ? r1 : r2;
      final low = r1 > r2 ? r2 : r1;
      var s = high * 2 + low / 10;
      if (suited) s += 1;
      return (s * 100).round();
    }

    hands.sort((a, b) => score(b).compareTo(score(a)));
    return List.unmodifiable(hands);
  })();

  static Set<String> topNHands(int percent) {
    var count = (169 * percent / 100).round();
    if (count > 169) count = 169;
    return handRanking.take(count).toSet();
  }
  static Future<TrainingPackTemplate> generatePushFoldPack({
    required String id,
    required String name,
    required int heroBbStack,
    required List<int> playerStacksBb,
    required HeroPosition heroPos,
    required List<String> heroRange,
    int anteBb = 0,
  }) async {
    return generatePushFoldPackSync(
      id: id,
      name: name,
      heroBbStack: heroBbStack,
      playerStacksBb: playerStacksBb,
      heroPos: heroPos,
      heroRange: heroRange,
      anteBb: anteBb,
    );
  }

  static TrainingPackTemplate generatePushFoldPackSync({
    required String id,
    required String name,
    required int heroBbStack,
    required List<int> playerStacksBb,
    required HeroPosition heroPos,
    required List<String> heroRange,
    int anteBb = 0,
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
      final ev = computePushEV(
        heroBbStack: heroBbStack,
        bbCount: playerStacksBb.length,
        heroHand: hand,
        anteBb: anteBb,
      );
      actions[0]![0].ev = ev;
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
