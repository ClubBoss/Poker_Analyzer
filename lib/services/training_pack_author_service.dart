import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../models/action_entry.dart';
import '../models/game_type.dart';
import '../helpers/training_pack_validator.dart';

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
  };

  static Map<String, String> get presets =>
      {for (final e in _presets.entries) e.key: e.value.name};

  TrainingPackTemplate generateFromPreset(String presetId) {
    final config = _presets[presetId];
    if (config == null) {
      throw ArgumentError('Unknown preset');
    }
    final spots = <TrainingPackSpot>[];
    for (var i = 0; i < config.hands.length; i++) {
      final hand = config.hands[i];
      final stacks = {'0': config.stack.toDouble(), '1': config.stack.toDouble()};
      final actions = {
        0: [
          ActionEntry(0, 0, 'push', amount: config.stack.toDouble(), ev: 0, icmEv: 0),
          ActionEntry(0, 1, 'fold'),
        ]
      };
      final spot = TrainingPackSpot(
        id: '${presetId}_${i + 1}',
        title: '$hand push',
        hand: HandData(
          heroCards: _firstCombo(hand),
          position: config.pos,
          heroIndex: 0,
          playerCount: 2,
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
      heroBbStack: config.stack,
      playerStacksBb: [config.stack, config.stack],
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
