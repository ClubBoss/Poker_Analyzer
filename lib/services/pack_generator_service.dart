import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../models/v2/training_pack_preset.dart';
import '../models/v2/training_pack_variant.dart';
import '../models/training_spot.dart';
import '../models/card_model.dart';
import '../models/action_entry.dart';
import '../models/game_type.dart';
import 'push_fold_ev_service.dart';
import 'icm_push_ev_service.dart';
import '../utils/template_coverage_utils.dart';
import 'range_library_service.dart';
import 'package:uuid/uuid.dart';

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
    List<String>? range = p.heroRange;
    if (range == null || range.isEmpty) {
      final loaded = await RangeLibraryService.instance.getRange(p.id);
      if (loaded.isNotEmpty) range = loaded;
    }
    List<TrainingPackSpot> spots;
    if (p.spots.isNotEmpty) {
      spots = [
        for (var i = 0; i < p.spots.length; i++)
          _fromTrainingSpot(p.spots[i], '${p.id}_${i + 1}')
      ];
    } else {
      spots = await autoGenerateSpots(
        id: p.id,
        stack: p.heroBbStack,
        players: p.playerStacksBb,
        pos: p.heroPos,
        count: p.spotCount,
        bbCallPct: p.bbCallPct,
        anteBb: p.anteBb,
        range: range,
      );
    }
    final tpl = TrainingPackTemplate(
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
      heroRange: range,
      createdAt: p.createdAt,
      lastGeneratedAt: DateTime.now(),
      isBuiltIn: true,
    );
    TemplateCoverageUtils.recountAll(tpl).applyTo(tpl.meta);
    return tpl;
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
    const evService = PushFoldEvService();
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
      final stacks = {
        for (var j = 0; j < playerStacksBb.length; j++)
          '$j': playerStacksBb[j].toDouble()
      };
      final spot = TrainingPackSpot(
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
      );
      evService.evaluate(spot, anteBb: anteBb);
      evService.evaluateIcm(spot, anteBb: anteBb);
      spots.add(spot);
    }
    final tpl = TrainingPackTemplate(
      id: id,
      name: name,
      gameType: GameType.tournament,
      spots: spots,
      heroBbStack: heroBbStack,
      playerStacksBb: List<int>.from(playerStacksBb),
      heroPos: heroPos,
      spotCount: spots.length,
      bbCallPct: bbCallPct,
      anteBb: anteBb,
      heroRange: List<String>.from(heroRange),
      createdAt: createdAt,
      lastGeneratedAt: DateTime.now(),
    );
    TemplateCoverageUtils.recountAll(tpl).applyTo(tpl.meta);
    return tpl;
  }

  static TrainingPackTemplate generatePushFoldRangePack({
    required String id,
    required String name,
    required int minBb,
    required int maxBb,
    required List<int> playerStacksBb,
    required HeroPosition heroPos,
    required List<String> heroRange,
    int anteBb = 0,
    int bbCallPct = 20,
    DateTime? createdAt,
  }) {
    final spots = <TrainingPackSpot>[];
    final diffs = [
      for (var i = 0; i < playerStacksBb.length; i++)
        playerStacksBb[i] - playerStacksBb.first
    ];
    for (var bb = minBb; bb <= maxBb; bb++) {
      final players = [for (final d in diffs) bb + d];
      final tpl = generatePushFoldPackSync(
        id: '${id}_${bb}bb',
        name: name,
        heroBbStack: bb,
        playerStacksBb: players,
        heroPos: heroPos,
        heroRange: heroRange,
        anteBb: anteBb,
        bbCallPct: bbCallPct,
        createdAt: createdAt,
      );
      spots.addAll(tpl.spots);
    }
    final tpl = TrainingPackTemplate(
      id: id,
      name: name,
      gameType: GameType.tournament,
      spots: spots,
      heroBbStack: minBb,
      playerStacksBb: List<int>.from(playerStacksBb),
      heroPos: heroPos,
      spotCount: spots.length,
      bbCallPct: bbCallPct,
      anteBb: anteBb,
      heroRange: List<String>.from(heroRange),
      createdAt: createdAt,
      lastGeneratedAt: DateTime.now(),
      meta: {'maxStack': maxBb},
    );
    TemplateCoverageUtils.recountAll(tpl).applyTo(tpl.meta);
    return tpl;
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
      for (final t in raw.split(RegExp('[,;s]+')))
        if (t.trim().isNotEmpty) t.trim()
    };
  }

  static String serializeRange(Set<String> range) => range.join(' ');

  static TrainingPackSpot _fromTrainingSpot(TrainingSpot spot, String id) {
    final heroCards = spot.heroIndex < spot.playerCards.length
        ? spot.playerCards[spot.heroIndex]
        : <CardModel>[];
    final hero = heroCards.map((c) => '${c.rank}${c.suit}').join(' ');
    final board = [for (final c in spot.boardCards) '${c.rank}${c.suit}'];
    final actions = <int, List<ActionEntry>>{};
    for (final a in spot.actions) {
      actions.putIfAbsent(a.street, () => []).add(ActionEntry(
        a.street,
        a.playerIndex,
        a.action,
        amount: a.amount,
        generated: a.generated,
        manualEvaluation: a.manualEvaluation,
        customLabel: a.customLabel,
      ));
    }
    final stacks = <String, double>{};
    for (var i = 0; i < spot.stacks.length; i++) {
      stacks['$i'] = spot.stacks[i].toDouble();
    }
    final pos = spot.heroIndex < spot.positions.length
        ? parseHeroPosition(spot.positions[spot.heroIndex])
        : HeroPosition.unknown;
    return TrainingPackSpot(
      id: id,
      hand: HandData(
        heroCards: hero,
        position: pos,
        heroIndex: spot.heroIndex,
        playerCount: spot.numberOfPlayers,
        board: board,
        actions: actions,
        stacks: stacks,
        anteBb: spot.anteBb,
      ),
      tags: List<String>.from(spot.tags),
    );
  }

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

    final tpl = TrainingPackTemplate(
      id: 'final_table_co',
      name: 'Final Table ICM',
      gameType: GameType.tournament,
      spots: spots,
      createdAt: createdAt,
    );
    TemplateCoverageUtils.recountAll(tpl).applyTo(tpl.meta);
    return tpl;
  }

  static Future<TrainingPackSpot> generateExampleSpot(
      TrainingPackTemplate template, TrainingPackVariant variant) async {
    var range = <String>[];
    if (variant.rangeId != null) {
      range = await RangeLibraryService.instance.getRange(variant.rangeId!);
    }
    if (range.isEmpty) {
      range = topNHands(25).toList();
    }
    final hand = range.first;
    final pos =
        variant.position == HeroPosition.unknown ? template.heroPos : variant.position;
    switch (variant.gameType) {
      case GameType.tournament:
        final tpl = generatePushFoldPackSync(
          id: const Uuid().v4(),
          name: 'Example',
          heroBbStack: 10,
          playerStacksBb: const [10, 10],
          heroPos: pos,
          heroRange: [hand],
          anteBb: 0,
          bbCallPct: 20,
        );
        return tpl.spots.first;
      case GameType.cash:
        return _generateCashExample(pos, hand);
    }
  }

  static TrainingPackSpot _generateCashExample(HeroPosition pos, String hand) {
    final stacks = {'0': 100.0, '1': 100.0};
    final actions = {
      0: [
        ActionEntry(0, 0, 'raise', amount: 3),
        ActionEntry(0, 1, 'call', amount: 3),
      ]
    };
    return TrainingPackSpot(
      id: const Uuid().v4(),
      title: 'Example',
      hand: HandData(
        heroCards: _firstCombo(hand),
        position: pos,
        heroIndex: 0,
        playerCount: 2,
        stacks: stacks,
        actions: actions,
      ),
      tags: const ['cash'],
    );
  }
}
