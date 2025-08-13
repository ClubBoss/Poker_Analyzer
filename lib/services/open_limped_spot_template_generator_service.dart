import 'dart:math';
import 'package:json2yaml/json2yaml.dart';

import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_template_set.dart';
import '../models/action_entry.dart';
import '../models/game_type.dart';
import '../core/training/engine/training_type_engine.dart';
import 'hand_range_library.dart';

/// Generates training pack template sets for SB limp pots vs BB.
///
/// Each generated [TrainingPackTemplateSet] contains a single preflop spot
/// where the villain in the small blind limps and the hero in the big blind
/// decides whether to isolate raise or check. Packs are tagged for Level II
/// study.
class OpenLimpedSpotTemplateGeneratorService {
  final Random _random;

  OpenLimpedSpotTemplateGeneratorService({Random? random})
      : _random = random ?? Random();

  /// Generates a list of [TrainingPackTemplateSet] objects representing
  /// SB limp spots vs BB.
  List<TrainingPackTemplateSet> generate({
    required int effectiveStack,
    required String heroRange,
    required Map<String, dynamic> bbResponseTendencies,
  }) {
    final hands = List<String>.from(HandRangeLibrary.getGroup(heroRange));
    hands.shuffle(_random);
    var count = hands.length;
    if (count > 10) count = 10;
    if (count < 5) count = hands.length;
    final selected = hands.take(count).toList();

    final sets = <TrainingPackTemplateSet>[];
    var idx = 1;
    for (final hand in selected) {
      final spot = _buildSpot(
        hand: hand,
        effectiveStack: effectiveStack,
        index: idx,
        bbResponseTendencies: bbResponseTendencies,
      );

      final tpl = TrainingPackTemplateV2(
        id: 'sb_limp_bb_${effectiveStack}bb_$idx',
        name: 'SB Limp vs BB (${effectiveStack}BB)',
        description: 'BB decision with $hand after SB limp',
        trainingType: TrainingType.pushFold,
        spots: [spot],
        spotCount: 1,
        gameType: GameType.tournament,
        bb: effectiveStack,
        positions: [HeroPosition.bb.name],
        tags: const ['preflop', 'limp', 'sbvsbb', 'LevelII'],
        meta: {
          'level': 2,
          'topic': 'SB limp',
          'bbResponseTendencies': bbResponseTendencies,
        },
      );

      sets.add(TrainingPackTemplateSet(template: tpl));
      idx++;
    }
    return sets;
  }

  /// Convenience method returning YAML representations of the generated sets.
  List<String> generateYaml({
    required int effectiveStack,
    required String heroRange,
    required Map<String, dynamic> bbResponseTendencies,
  }) {
    final sets = generate(
      effectiveStack: effectiveStack,
      heroRange: heroRange,
      bbResponseTendencies: bbResponseTendencies,
    );
    return sets.map(_exportYaml).toList();
  }

  String _exportYaml(TrainingPackTemplateSet set) {
    final map = {
      'template': set.template.toJson(),
      if (set.variants.isNotEmpty) 'variants': set.variants,
      if (set.entries.isNotEmpty)
        'templateSet': [
          for (final e in set.entries)
            {
              'name': e.name,
              if (e.tags.isNotEmpty) 'tags': e.tags,
              'constraints': e.constraints.toJson(),
            }
        ],
      if (set.linePatterns.isNotEmpty)
        'linePatterns': [for (final p in set.linePatterns) p.toJson()],
    };
    return json2yaml(map, yamlStyle: YamlStyle.pubspecYaml);
  }

  TrainingPackSpot _buildSpot({
    required String hand,
    required int effectiveStack,
    required int index,
    required Map<String, dynamic> bbResponseTendencies,
  }) {
    final heroCards = _firstCombo(hand);
    final actions = <int, List<ActionEntry>>{
      0: [
        ActionEntry(0, 1, 'limp', amount: 1),
        ActionEntry(0, 0, 'raise', amount: 4),
        ActionEntry(0, 1, 'fold'),
      ],
    };
    final handData = HandData(
      heroCards: heroCards,
      position: HeroPosition.bb,
      heroIndex: 0,
      playerCount: 2,
      stacks: {
        '0': effectiveStack.toDouble(),
        '1': effectiveStack.toDouble(),
      },
      actions: actions,
    );

    return TrainingPackSpot(
      id: 'spot_$index',
      hand: handData,
      villainAction: 'limp',
      heroOptions: const ['isoRaise', 'check'],
      tags: const ['preflop', 'limp', 'sbvsbb', 'LevelII'],
      meta: {
        'bbResponseTendencies': bbResponseTendencies,
      },
    );
  }

  String _firstCombo(String hand) {
    const suits = ['h', 'd', 'c', 's'];
    if (hand.length == 2) {
      final r = hand[0];
      return '$r${suits[0]} $r${suits[1]}';
    }
    final r1 = hand[0];
    final r2 = hand[1];
    final suited = hand[2].toLowerCase() == 's';
    if (suited) return '$r1${suits[0]} $r2${suits[0]}';
    return '$r1${suits[0]} $r2${suits[1]}';
  }
}
