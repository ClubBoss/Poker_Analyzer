import 'dart:math';
import 'package:test/test.dart';
import 'package:poker_analyzer/services/training_spot_generator_service.dart';

void main() {
  test('generateRandomFlop respects suitPattern and excludedRanks', () {
    final svc = TrainingSpotGeneratorService(random: Random(42));
    final board = svc.generateRandomFlop(boardFilter: {
      'suitPattern': 'rainbow',
      'excludedRanks': ['A']
    });
    expect(board.length, 3);
    expect(board.any((c) => c.rank == 'A'), false);
    expect(board.map((c) => c.suit).toSet().length, 3);
  });

  test('generateRandomFlop supports requiredRanks', () {
    final svc = TrainingSpotGeneratorService(random: Random(1));
    final board = svc.generateRandomFlop(boardFilter: {
      'requiredRanks': ['A', 'K']
    });
    final ranks = board.map((c) => c.rank).toSet();
    expect(ranks.contains('A'), true);
    expect(ranks.contains('K'), true);
  });
}
