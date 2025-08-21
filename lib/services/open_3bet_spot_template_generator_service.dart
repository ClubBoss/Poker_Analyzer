import 'dart:math';

import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/action_entry.dart';
import '../models/game_type.dart';
import 'hand_range_library.dart';
import '../core/training/engine/training_type_engine.dart';
import '../core/training/export/training_pack_exporter_v2.dart';

/// Generates training pack templates for common 3bet-push spots.
///
/// The service samples hands from [heroRange] and builds one
/// [TrainingPackTemplateV2] per hand.  Each template contains a single
/// preflop spot where the villain opens and the hero responds with a
/// 3bet shove.  Packs are tagged for Level II study.
class Open3betSpotTemplateGeneratorService {
  final Random _random;
  final TrainingPackExporterV2 _exporter;

  Open3betSpotTemplateGeneratorService({
    Random? random,
    TrainingPackExporterV2? exporter,
  }) : _random = random ?? Random(),
       _exporter = exporter ?? const TrainingPackExporterV2();

  /// Generates a list of [TrainingPackTemplateV2] objects representing
  /// 3bet-push spots.
  List<TrainingPackTemplateV2> generate({
    required HeroPosition heroPosition,
    required HeroPosition villainPosition,
    required int effectiveStack,
    required String heroRange,
    required String villainRange,
    String threeBetType = 'allin',
  }) {
    final hands = List<String>.from(HandRangeLibrary.getGroup(heroRange));
    hands.shuffle(_random);
    var count = hands.length;
    if (count > 10) count = 10;
    if (count < 5) count = hands.length; // Use all available if fewer than 5.
    final selected = hands.take(count).toList();

    final templates = <TrainingPackTemplateV2>[];
    var idx = 1;
    for (final hand in selected) {
      final spot = _buildSpot(
        hand: hand,
        heroPosition: heroPosition,
        villainPosition: villainPosition,
        effectiveStack: effectiveStack,
        villainRange: villainRange,
        threeBetType: threeBetType,
        index: idx,
      );

      final tpl = TrainingPackTemplateV2(
        id: '3bet_${heroPosition.name}_vs_${villainPosition.name}_${effectiveStack}bb_$idx',
        name:
            '3bet Push ${heroPosition.label} vs ${villainPosition.label} (${effectiveStack}BB)',
        description:
            '${heroPosition.label} 3bet shoves $hand vs ${villainPosition.label} open',
        trainingType: TrainingType.pushFold,
        spots: [spot],
        spotCount: 1,
        gameType: GameType.tournament,
        bb: effectiveStack,
        positions: [heroPosition.name],
        tags: const ['preflop', '3bet', 'LevelII'],
        meta: {'level': 2, 'topic': '3bet push'},
      );
      templates.add(tpl);
      idx++;
    }
    return templates;
  }

  /// Convenience method returning YAML representations of the generated packs.
  List<String> generateYaml({
    required HeroPosition heroPosition,
    required HeroPosition villainPosition,
    required int effectiveStack,
    required String heroRange,
    required String villainRange,
    String threeBetType = 'allin',
  }) {
    final packs = generate(
      heroPosition: heroPosition,
      villainPosition: villainPosition,
      effectiveStack: effectiveStack,
      heroRange: heroRange,
      villainRange: villainRange,
      threeBetType: threeBetType,
    );
    return packs.map(_exporter.exportYaml).toList();
  }

  TrainingPackSpot _buildSpot({
    required String hand,
    required HeroPosition heroPosition,
    required HeroPosition villainPosition,
    required int effectiveStack,
    required String villainRange,
    required String threeBetType,
    required int index,
  }) {
    final heroCards = _firstCombo(hand);
    final actions = <int, List<ActionEntry>>{
      0: [
        ActionEntry(0, 1, 'open', amount: 2.5),
        ActionEntry(0, 0, 'push', amount: effectiveStack.toDouble()),
        ActionEntry(0, 1, 'fold'),
      ],
    };
    final handData = HandData(
      heroCards: heroCards,
      position: heroPosition,
      heroIndex: 0,
      playerCount: 2,
      stacks: {'0': effectiveStack.toDouble(), '1': effectiveStack.toDouble()},
      actions: actions,
    );

    return TrainingPackSpot(
      id: 'spot_$index',
      hand: handData,
      villainAction: 'open 2.5',
      heroOptions: const ['3betPush', 'fold'],
      tags: const ['preflop', '3bet', 'LevelII'],
      meta: {'villainRange': villainRange, 'threeBetType': threeBetType},
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
