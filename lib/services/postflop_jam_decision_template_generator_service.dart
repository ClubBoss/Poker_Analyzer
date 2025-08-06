import 'dart:math';

import '../helpers/board_filtering_params_builder.dart';
import '../models/action_entry.dart';
import '../models/game_type.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../core/training/engine/training_type_engine.dart';
import 'full_board_generator_service.dart';
import 'hand_range_library.dart';
import 'pack_generator_service.dart';

/// Generates postflop jam decision training pack templates.
///
/// The service builds one [TrainingPackTemplateV2] per sampled hand from
/// [heroHandGroup]. Each template contains a single spot where the hero either
/// faces an all-in or considers shoving. Packs are tagged for Level III study.
class PostflopJamDecisionTemplateGeneratorService {
  final Random _random;
  final FullBoardGeneratorService _boardGenerator;

  PostflopJamDecisionTemplateGeneratorService({
    Random? random,
    FullBoardGeneratorService? boardGenerator,
  })  : _random = random ?? Random(),
        _boardGenerator =
            boardGenerator ?? FullBoardGeneratorService(random: random ?? Random());

  /// Generates jam decision templates for river or delayed turn scenarios.
  List<TrainingPackTemplateV2> generate({
    required String boardTexture,
    required String heroHandGroup,
    required String villainLine,
    required int effectiveStack,
    required int potSize,
    bool delayedTurn = false,
  }) {
    final hands = _resolveHands(heroHandGroup);
    hands.shuffle(_random);
    var count = hands.length;
    if (count > 10) count = 10;
    if (count < 5) count = hands.length;
    final selected = hands.take(count).toList();
    final boardFilter = BoardFilteringParamsBuilder.build([boardTexture]);
    final templates = <TrainingPackTemplateV2>[];

    for (var i = 0; i < selected.length; i++) {
      final boardResult = delayedTurn
          ? _boardGenerator.generatePartialBoard(
              stages: 4, boardFilterParams: boardFilter)
          : _boardGenerator.generateFullBoard(
              boardFilterParams: boardFilter);
      final board =
          boardResult.cards.map((c) => '${c.rank}${c.suit}').toList();
      final heroPos = _random.nextBool() ? HeroPosition.btn : HeroPosition.bb;
      final facingJam = delayedTurn ? true : _random.nextBool();
      final spot = _buildSpot(
        hand: selected[i],
        board: board,
        heroPosition: heroPos,
        villainLine: villainLine,
        effectiveStack: effectiveStack,
        potSize: potSize,
        facingJam: facingJam,
        index: i + 1,
        boardTexture: boardTexture,
        delayedTurn: delayedTurn,
      );
      final tpl = TrainingPackTemplateV2(
        id: delayedTurn
            ? 'delayed_turn_jam_${effectiveStack}bb_${i + 1}'
            : 'river_jam_${effectiveStack}bb_${i + 1}',
        name: delayedTurn
            ? 'Delayed Turn Jam Decision ${i + 1}'
            : 'River Jam Decision ${i + 1}',
        description:
            '${heroPos == HeroPosition.btn ? 'IP' : 'OOP'} decision with ${selected[i]}',
        trainingType: TrainingType.postflopJamDecision,
        spots: [spot],
        spotCount: 1,
        gameType: GameType.tournament,
        bb: effectiveStack,
        positions: [heroPos.name],
        tags: delayedTurn
            ? const ['turn', 'jam', 'delayCbet', 'call', 'fold']
            : const ['river', 'jam', 'call', 'potOdds'],
        meta: delayedTurn
            ? const {
                'level': 'intermediate/advanced',
                'goal': 'turnDecision',
                'theme': 'postflop',
              }
            : const {
                'level': 'intermediate/advanced',
                'goal': 'riverDecision',
                'theme': 'postflop',
              },
      );
      templates.add(tpl);
    }

    return templates;
  }

  List<String> _resolveHands(String group) {
    try {
      return List<String>.from(HandRangeLibrary.getGroup(group));
    } catch (_) {
      return PackGeneratorService.parseRangeString(group).toList();
    }
  }

  TrainingPackSpot _buildSpot({
    required String hand,
    required List<String> board,
    required HeroPosition heroPosition,
    required String villainLine,
    required int effectiveStack,
    required int potSize,
    required bool facingJam,
    required int index,
    required String boardTexture,
    required bool delayedTurn,
  }) {
    final heroCards = _firstCombo(hand);
    final actions = <int, List<ActionEntry>>{
      if (delayedTurn)
        2: [
          ActionEntry(2, 0, 'bet',
              amount: min(potSize.toDouble(), effectiveStack.toDouble())),
          ActionEntry(2, 1, 'push', amount: effectiveStack.toDouble()),
          ActionEntry(2, 0, 'call', amount: effectiveStack.toDouble()),
          ActionEntry(2, 0, 'fold'),
        ]
      else
        3: facingJam
            ? [
                ActionEntry(3, 1, 'push',
                    amount: effectiveStack.toDouble()),
                ActionEntry(3, 0, 'call',
                    amount: effectiveStack.toDouble()),
                ActionEntry(3, 0, 'fold'),
              ]
            : [
                ActionEntry(3, 0, 'push',
                    amount: effectiveStack.toDouble()),
                ActionEntry(3, 1, 'fold'),
              ],
    };
    final handData = HandData(
      heroCards: heroCards,
      position: heroPosition,
      heroIndex: 0,
      playerCount: 2,
      stacks: {'0': effectiveStack.toDouble(), '1': effectiveStack.toDouble()},
      board: board,
      actions: actions,
    );
    return TrainingPackSpot(
      id: 'spot_$index',
      hand: handData,
      villainAction: 'jam',
      heroOptions: delayedTurn
          ? const ['call', 'fold']
          : facingJam
              ? const ['call', 'fold']
              : const ['shove', 'fold'],
      tags: delayedTurn
          ? const ['turn', 'jam', 'delayCbet', 'call', 'fold']
          : const ['river', 'jam', 'call', 'potOdds'],
      meta: {
        'villainLine': villainLine,
        'potSize': potSize,
        'boardTexture': boardTexture,
        'facingJam': delayedTurn ? true : facingJam,
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
    final suited = hand.length > 2 && hand[2].toLowerCase() == 's';
    if (suited) return '$r1${suits[0]} $r2${suits[0]}';
    return '$r1${suits[0]} $r2${suits[1]}';
  }
}

