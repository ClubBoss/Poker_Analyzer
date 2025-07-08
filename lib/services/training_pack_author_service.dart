import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../models/action_entry.dart';
import '../models/game_type.dart';
import '../helpers/training_pack_validator.dart';
import 'push_fold_ev_service.dart';
import 'icm_push_ev_service.dart';

class TrainingPackAuthorService {
  static final Map<String, _PresetConfig> _presets = {
    '10bb_co_vs_bb': _PresetConfig(
      '10bb CO vs BB',
      HeroPosition.co,
      10,
      [
        'AJo',
        'ATo',
        'KQo',
        'QJo',
        'JTo',
        'T9s',
        '98s',
        '77',
        '66',
        '55',
      ],
    ),
    '10bb_sb_vs_bb': _PresetConfig(
      '10bb SB vs BB',
      HeroPosition.sb,
      10,
      [
        'A9o',
        'A8o',
        'A5s',
        'KQo',
        'Q9s',
        'J9s',
        'T8s',
        '66',
        '55',
        '44',
      ],
    ),
    '15bb_hj_vs_bb': _PresetConfig(
      '15bb HJ vs BB',
      HeroPosition.mp,
      15,
      [
        'AJs',
        'ATo',
        'KQo',
        'KJs',
        'QJs',
        'JTs',
        'T9s',
        '99',
        '88',
      ],
    ),
    '25bb_co_vs_btn_3bet': _PresetConfig(
      '25bb CO vs BTN 3bet',
      HeroPosition.co,
      25,
      [
        'AQo',
        'AJs',
        'KQs',
        'TT',
        '99',
        '88',
        'A5s',
        'KQo',
      ],
    ),
    'icm_final_table_6max_12bb_co': _PresetConfig(
      'ICM Final Table 6max 12bb CO',
      HeroPosition.co,
      12,
      [
        'ATo',
        'A9s',
        'KQo',
        'KJs',
        'QTs',
        'JTs',
      ],
    ),
  };

  static Map<String, String> get presets =>
      {for (final e in _presets.entries) e.key: e.value.name};

  TrainingPackTemplate generateFromPreset(String presetId) {
    final config = _presets[presetId];
    if (config == null) {
      throw ArgumentError('Unknown preset');
    }
    final is3bet = presetId == '25bb_co_vs_btn_3bet';
    final isIcm = presetId == 'icm_final_table_6max_12bb_co';
    final spots = <TrainingPackSpot>[];
    for (var i = 0; i < config.hands.length; i++) {
      final hand = config.hands[i];
      Map<String, double> stacks;
      Map<int, List<ActionEntry>> actions;
      int playerCount;
      int heroIndex = 0;
      if (is3bet) {
        stacks = {'0': config.stack.toDouble(), '1': config.stack.toDouble()};
        actions = {
          0: [
            ActionEntry(0, 0, 'raise', amount: 2.5, ev: 0, icmEv: 0),
            ActionEntry(0, 1, 'raise', amount: 7.5),
          ]
        };
        playerCount = 2;
      } else if (isIcm) {
        const playerStacks = [25, 20, 12, 18, 9, 6];
        heroIndex = 2;
        actions = {
          0: [
            ActionEntry(0, heroIndex, 'push',
                amount: playerStacks[heroIndex].toDouble()),
            for (var j = 0; j < playerStacks.length; j++)
              if (j != heroIndex) ActionEntry(0, j, 'fold'),
          ]
        };
        final chipEv = computePushEV(
          heroBbStack: playerStacks[heroIndex],
          bbCount: playerStacks.length - 1,
          heroHand: hand,
          anteBb: 0,
        );
        actions[0]![0].ev = chipEv;
        actions[0]![0].icmEv = computeIcmPushEV(
          chipStacksBb: playerStacks,
          heroIndex: heroIndex,
          heroHand: hand,
          chipPushEv: chipEv,
        );
        stacks = {
          for (var j = 0; j < playerStacks.length; j++)
            '$j': playerStacks[j].toDouble()
        };
        playerCount = playerStacks.length;
      } else {
        stacks = {'0': config.stack.toDouble(), '1': config.stack.toDouble()};
        actions = {
          0: [
            ActionEntry(0, 0, 'push',
                amount: config.stack.toDouble(), ev: 0, icmEv: 0),
            ActionEntry(0, 1, 'fold'),
          ]
        };
        playerCount = 2;
      }
      final spot = TrainingPackSpot(
        id: '${presetId}_${i + 1}',
        title: is3bet ? '$hand open 3bet' : '$hand push',
        hand: HandData(
          heroCards: _firstCombo(hand),
          position: config.pos,
          heroIndex: heroIndex,
          playerCount: playerCount,
          stacks: stacks,
          actions: actions,
          anteBb: 0,
        ),
      );
      if (validateSpot(spot, i).isEmpty) spots.add(spot);
    }
    return TrainingPackTemplate(
      id: presetId,
      name: config.name,
      gameType: config.gameType,
      spots: spots,
      heroBbStack: isIcm ? 12 : config.stack,
      playerStacksBb: isIcm
          ? const [25, 20, 12, 18, 9, 6]
          : [config.stack, config.stack],
      heroPos: config.pos,
      spotCount: spots.length,
      bbCallPct: 0,
      anteBb: 0,
      createdAt: DateTime.now(),
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
    if (suited) return '$r1${suits[0]} $r2${suits[0]}';
    return '$r1${suits[0]} $r2${suits[1]}';
  }
}

class _PresetConfig {
  final String name;
  final HeroPosition pos;
  final int stack;
  final List<String> hands;
  final GameType gameType;
  const _PresetConfig(this.name, this.pos, this.stack, this.hands,
      {this.gameType = GameType.tournament});
}
