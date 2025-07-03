import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../models/v2/training_pack_preset.dart';
import '../models/action_entry.dart';
import '../models/game_type.dart';
import 'push_fold_ev_service.dart';
import 'icm_push_ev_service.dart';

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
    return List<String>.unmodifiable(hands);
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
    int bbCallPct = 20,
    DateTime? createdAt,
  }) async {
    return generatePushFoldPackSync(
      id: id,
      name: name,
      heroBbStack: heroBbStack,
      playerStacksBb: playerStacksBb,
      heroPos: heroPos,
      heroRange: heroRange,
      anteBb: anteBb,
      bbCallPct: bbCallPct,
      createdAt: createdAt,
    );
  }

  static Future<List<TrainingPackSpot>> autoGenerateSpots({
    required String id,
    required int stack,
    required List<int> players,
    required HeroPosition pos,
    int count = 20,
    int bbCallPct = 20,
    int anteBb = 0,
    List<String>? range,
  }) async {
    final tpl = generatePushFoldPackSync(
      id: id,
      name: '',
      heroBbStack: stack,
      playerStacksBb: players,
      heroPos: pos,
      heroRange: range ?? topNHands(25).toList(),
      anteBb: anteBb,
      bbCallPct: bbCallPct,
      createdAt: DateTime.now(),
    );
    return tpl.spots.take(count).toList();
  }

  static Future<TrainingPackTemplate> generatePackFromPreset(
      TrainingPackPreset p) async {
    final spots = await autoGenerateSpots(
      id: p.id,
      stack: p.heroBbStack,
      players: p.playerStacksBb,
      pos: p.heroPos,
      count: p.spotCount,
      bbCallPct: p.bbCallPct,
      anteBb: p.anteBb,
      range: p.heroRange,
    );
    return TrainingPackTemplate(
      id: p.id,
      name: p.name,
      description: p.description,
      gameType: p.gameType,
      spots: spots,
      heroBbStack: p.heroBbStack,
      playerStacksBb: List<int>.from(p.playerStacksBb),
      heroPos: p.heroPos,
      spotCount: p.spotCount,
      bbCallPct: p.bbCallPct,
      anteBb: p.anteBb,
      heroRange: p.heroRange,
      createdAt: p.createdAt,
      lastGeneratedAt: DateTime.now(),
    )..recountCoverage();
  }

  static TrainingPackTemplate generatePushFoldPackSync({
    required String id,
    required String name,
    required int heroBbStack,
    required List<int> playerStacksBb,
    required HeroPosition heroPos,
    required List<String> heroRange,
    int anteBb = 0,
    int bbCallPct = 20,
    DateTime? createdAt,
  }) {
    final spots = <TrainingPackSpot>[];
    final isHeadsUp = playerStacksBb.length == 2;
    const idxBB = 1;
    final callCutoff =
        (PackGeneratorService.handRanking.length * bbCallPct / 100).round();
    for (var i = 0; i < heroRange.length; i++) {
      final hand = heroRange[i];
      final heroCards = _firstCombo(hand);
      final actions = {
        0: [
          ActionEntry(0, 0, 'push', amount: heroBbStack.toDouble()),
          for (var j = 1; j < playerStacksBb.length; j++)
            if (isHeadsUp &&
                j == idxBB &&
                handRanking.indexOf(hand) < callCutoff)
              ActionEntry(0, j, 'call', amount: heroBbStack.toDouble())
            else
              ActionEntry(0, j, 'fold'),
        ]
      };
      final ev = computePushEV(
        heroBbStack: heroBbStack,
        bbCount: playerStacksBb.length - 1,
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
            anteBb: anteBb,
          ),
          tags: const ['pushfold'],
        ),
      );
    }
    return TrainingPackTemplate(
      id: id,
      name: name,
      gameType: GameType.tournament,
      spots: spots,
      createdAt: createdAt,
    )..recountCoverage();
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
      for (final t in raw.split(RegExp('[,;\s]+')))
        if (t.trim().isNotEmpty) t.trim()
    };
  }

  static String serializeRange(Set<String> range) => range.join(' ');

  static TrainingPackTemplate generateFinalTablePack({DateTime? createdAt}) {
    const stacks = [5, 10, 20, 30, 40, 50, 60, 70, 80];
    const heroIndex = 3;
    const pos = HeroPosition.co;
    final range = topNHands(10).toList();
    final spots = <TrainingPackSpot>[];

    for (var i = 0; i < range.length; i++) {
      final actions = {
        0: [
          ActionEntry(0, heroIndex, 'push',
              amount: stacks[heroIndex].toDouble()),
          for (var j = 0; j < stacks.length; j++)
            if (j != heroIndex) ActionEntry(0, j, 'fold'),
        ]
      };
      final stacksMap = {
        for (var j = 0; j < stacks.length; j++) '$j': stacks[j].toDouble()
      };
      final chipEv = computePushEV(
        heroBbStack: stacks[heroIndex],
        bbCount: stacks.length - 1,
        heroHand: range[i],
        anteBb: 0,
      );
      actions[0]![0].ev = chipEv;
      actions[0]![0].icmEv = computeIcmPushEV(
        chipStacksBb: stacks,
        heroIndex: heroIndex,
        heroHand: range[i],
        chipPushEv: chipEv,
      );
      spots.add(
        TrainingPackSpot(
          id: 'finaltable_${i + 1}',
          title: '${range[i]} push',
          hand: HandData(
            heroCards: _firstCombo(range[i]),
            position: pos,
            heroIndex: heroIndex,
            playerCount: stacks.length,
            stacks: stacksMap,
            actions: actions,
            anteBb: 0,
          ),
          tags: const ['finaltable'],
        ),
      );
    }

    return TrainingPackTemplate(
      id: 'final_table_co',
      name: 'Final Table ICM',
      gameType: GameType.tournament,
      spots: spots,
      createdAt: createdAt,
    )..recountCoverage();
  }
}
