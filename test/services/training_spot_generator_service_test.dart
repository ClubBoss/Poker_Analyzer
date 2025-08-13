import 'dart:math';
import 'package:test/test.dart';
import 'package:poker_analyzer/services/training_spot_generator_service.dart';

void main() {
  test('generateRandomBoard respects suitPattern and excludedRanks', () {
    final svc = TrainingSpotGeneratorService(random: Random(42));
    final board = svc.generateRandomBoard(
      street: 'flop',
      boardFilter: {
        'suitPattern': 'rainbow',
        'excludedRanks': ['A']
      },
    );
    expect(board.length, 3);
    expect(board.any((c) => c.rank == 'A'), false);
    expect(board.map((c) => c.suit).toSet().length, 3);
  });

  test('generateRandomBoard supports requiredRanks on river', () {
    final svc = TrainingSpotGeneratorService(random: Random(1));
    final board = svc.generateRandomBoard(
      street: 'river',
      boardFilter: {
        'requiredRanks': ['A', 'K']
      },
    );
    final ranks = board.map((c) => c.rank).toSet();
    expect(board.length, 5);
    expect(ranks.contains('A'), true);
    expect(ranks.contains('K'), true);
  });

  test('generate builds board up to targetStreet without card overlap', () {
    final svc = TrainingSpotGeneratorService(random: Random(3));
    final spot = svc
        .generate(SpotGenerationParams(
          position: 'btn',
          villainAction: 'check',
          handGroup: ['AKs'],
          count: 1,
          targetStreet: 'turn',
        ))
        .first;
    expect(spot.boardCards.length, 4);
    final hero = spot.playerCards[spot.heroIndex];
    final clash = spot.boardCards
        .any((b) => hero.any((h) => h.rank == b.rank && h.suit == b.suit));
    expect(clash, false);
  });

  test('boardStages generates river board when set to 5', () {
    final svc = TrainingSpotGeneratorService(random: Random(4));
    final spot = svc
        .generate(SpotGenerationParams(
          position: 'btn',
          villainAction: 'check',
          handGroup: ['AKs'],
          count: 1,
          boardStages: 5,
        ))
        .first;
    expect(spot.boardCards.length, 5);
  });
}
