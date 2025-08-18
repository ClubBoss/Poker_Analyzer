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
      hands[i] = Hand.solveHand([...boardStr, ...cards.map(_s)]);
    }
    if (hands.isEmpty) return [];
    final winners = Hand.winners(hands.values.toList());
    return [
      for (final e in hands.entries)
        if (winners.contains(e.value)) e.key,
    ];
  }

  static String _s(CardModel c) {
    const map = {'♠': 's', '♥': 'h', '♦': 'd', '♣': 'c'};
    return '${c.rank}${map[c.suit] ?? c.suit}';
  }

  static Map<int, Hand> buildHands(
    List<List<CardModel>> revealed,
    List<CardModel> board,
  ) {
    if (board.length < 5) return {};
    final boardStr = board.take(5).map(_s).toList();
    final Map<int, Hand> hands = {};
    for (int i = 0; i < revealed.length; i++) {
      final cards = revealed[i];
      if (cards.length < 2) continue;
      hands[i] = Hand.solveHand([...boardStr, ...cards.map(_s)]);
    }
    return hands;
  }

  static Map<int, double> splitWithSidePots({
    required Map<int, Hand> showdownHands,
    required List<double> bets,
    required List<double> allInAt,
    required double mainPot,
  }) {
    final result = <int, double>{};
    final active = showdownHands.keys.toSet();
    final levels = [
      for (final v in allInAt)
        if (v.isFinite) v,
    ]..sort();
    double remaining = mainPot;
    double prev = 0;
    for (final level in levels) {
      final participants = [
        for (int i = 0; i < allInAt.length; i++)
          if (allInAt[i] >= level || !allInAt[i].isFinite) i,
      ];
      if (participants.isEmpty) continue;
      double pot = (level - prev) * participants.length;
      if (pot > remaining) pot = remaining;
      remaining -= pot;
      final eligibles = [
        for (final p in participants)
          if (showdownHands.containsKey(p)) p,
      ];
      if (pot > 0 && eligibles.isNotEmpty) {
        final hands = {for (final p in eligibles) p: showdownHands[p]!};
        final winners = Hand.winners(hands.values.toList());
        final share = pot / winners.length;
        for (final e in hands.entries) {
          if (winners.contains(e.value)) {
            result[e.key] = (result[e.key] ?? 0) + share;
          }
        }
      }
      active.removeWhere((p) => allInAt[p] == level);
      prev = level;
      if (remaining <= 0) break;
    }
    if (remaining > 0 && active.isNotEmpty) {
      final hands = {for (final p in active) p: showdownHands[p]!};
      final winners = Hand.winners(hands.values.toList());
      final share = remaining / winners.length;
      for (final e in hands.entries) {
        if (winners.contains(e.value)) {
          result[e.key] = (result[e.key] ?? 0) + share;
        }
      }
    }
    return result;
  }
}
