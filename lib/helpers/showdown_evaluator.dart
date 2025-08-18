import 'package:poker_solver/poker_solver.dart';
import '../models/card_model.dart';

String _toSolver(CardModel c) {
  final suitMap = {'♠': 's', '♥': 'h', '♦': 'd', '♣': 'c'};
  return '${c.rank}${suitMap[c.suit] ?? c.suit}';
}

/// Determine winning player indices based on board and hole cards.
List<int> determineWinners(
  List<CardModel> board,
  Map<int, List<CardModel>> playerCards,
) {
  if (board.length < 5) return [];
  final boardStr = board.take(5).map(_toSolver).toList();
  final Map<int, Hand> hands = {};
  playerCards.forEach((index, cards) {
    if (cards.length < 2) return;
    final all = [...boardStr, ...cards.map(_toSolver)];
    hands[index] = Hand.solveHand(all);
  });
  if (hands.isEmpty) return [];
  final winningHands = Hand.winners(hands.values.toList());
  return [
    for (final entry in hands.entries)
      if (winningHands.contains(entry.value)) entry.key,
  ];
}
