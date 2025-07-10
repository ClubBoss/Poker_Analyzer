import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/models/card_model.dart';
import 'package:poker_analyzer/models/player_model.dart';
import 'package:poker_analyzer/models/saved_hand.dart';
import 'package:poker_analyzer/services/diff_snapshot_service.dart';

void main() {
  test('diff compute and apply round trip', () {
    final service = DiffSnapshotService();
    final hand1 = SavedHand(
      name: 'h1',
      heroIndex: 0,
      heroPosition: 'BTN',
      numberOfPlayers: 2,
      playerCards: const [[], []],
      boardCards: const [],
      boardStreet: 0,
      actions: const [],
      stackSizes: const {0: 100, 1: 100},
      playerPositions: const {0: 'BTN', 1: 'BB'},
      playerTypes: const {0: PlayerType.unknown, 1: PlayerType.unknown},
    );
    final hand2 = hand1.copyWith(
      heroPosition: 'SB',
      boardStreet: 1,
      boardCards: const [CardModel(rank: 'A', suit: '♠')],
      actions: [ActionEntry(1, 1, 'bet')],
    );
    final diff = service.compute(hand1, hand2);
    final forward = service.apply(hand1, diff.forward);
    expect(forward.heroPosition, 'SB');
    expect(forward.boardStreet, 1);
    expect(forward.boardCards.length, 1);
    expect(forward.actions.length, 1);
    final back = service.apply(forward, diff.backward);
    expect(back.heroPosition, 'BTN');
    expect(back.boardStreet, 0);
    expect(back.boardCards, isEmpty);
    expect(back.actions, isEmpty);
  });
}
