import 'package:poker_solver/poker_solver.dart';

import '../models/card_model.dart';

class HandEvaluator {
  static List<int> evaluateShowdown(
    List<List<CardModel>> revealed,
    List<CardModel> board,
  ) {
    if (board.length < 5) return [];
    final boardStr = board.take(5).map(_s).toList();
    final Map<int, Hand> hands = {};
    for (int i = 0; i < revealed.length; i++) {
      final cards = revealed[i];
      if (cards.length < 2) continue;
      hands[i] = Hand.solveHand([
        ...boardStr,
        ...cards.map(_s),
      ]);
    }
    if (hands.isEmpty) return [];
    final winners = Hand.winners(hands.values.toList());
    return [
      for (final e in hands.entries)
        if (winners.contains(e.value)) e.key
    ];
  }

  static String _s(CardModel c) {
    const map = {'♠': 's', '♥': 'h', '♦': 'd', '♣': 'c'};
    return '${c.rank}${map[c.suit] ?? c.suit}';
  }
}

