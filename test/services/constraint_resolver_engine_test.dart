import 'package:test/test.dart';
import 'package:poker_analyzer/services/constraint_resolver_engine.dart';
import 'package:poker_analyzer/models/training_spot.dart';
import 'package:poker_analyzer/models/card_model.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/models/player_model.dart';

void main() {
  TrainingSpot buildSpot({List<CardModel>? board, String heroPos = 'btn'}) {
    return TrainingSpot(
      playerCards: [
        [CardModel(rank: 'A', suit: 's'), CardModel(rank: 'K', suit: 'd')],
        for (int i = 0; i < 5; i++) <CardModel>[],
      ],
      boardCards: board ??
          [
            CardModel(rank: '2', suit: 'h'),
            CardModel(rank: '7', suit: 'c'),
            CardModel(rank: '9', suit: 'd')
          ],
      actions: const <ActionEntry>[],
      heroIndex: 0,
      numberOfPlayers: 6,
      playerTypes: List.filled(6, PlayerType.unknown),
      positions: List.filled(6, ''),
      stacks: List.filled(6, 100),
      heroPosition: heroPos,
    );
  }

  test('validates position and street', () {
    final spot = buildSpot();
    final params = ConstraintResolverEngine.normalizeParams({
      'positions': ['btn'],
      'streets': ['flop'],
    });
    expect(ConstraintResolverEngine.isValidSpot(spot, params), isTrue);

    final bad = ConstraintResolverEngine.normalizeParams({
      'positions': ['hj'],
    });
    expect(ConstraintResolverEngine.isValidSpot(spot, bad), isFalse);
  });

  test('applies board texture filter', () {
    final spot = buildSpot(
      board: [
        CardModel(rank: 'A', suit: 's'),
        CardModel(rank: 'K', suit: 'h'),
        CardModel(rank: '2', suit: 'd'),
      ],
    );
    final params = ConstraintResolverEngine.normalizeParams({
      'boardFilter': ['aceHigh'],
    });
    expect(ConstraintResolverEngine.isValidSpot(spot, params), isTrue);
    final failParams = ConstraintResolverEngine.normalizeParams({
      'boardFilter': ['low'],
    });
    expect(ConstraintResolverEngine.isValidSpot(spot, failParams), isFalse);
  });
}
