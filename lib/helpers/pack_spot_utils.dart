import '../models/saved_hand.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/card_model.dart';

SavedHand handFromPackSpot(TrainingPackSpot spot, {int anteBb = 0}) {
  final parts = spot.hand.heroCards
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .toList();
  final cards = [
    for (final p in parts) CardModel(rank: p[0], suit: p.substring(1))
  ];
  final playerCards = [
    for (int i = 0; i < spot.hand.playerCount; i++) <CardModel>[]
  ];
  if (cards.length >= 2 && spot.hand.heroIndex < playerCards.length) {
    playerCards[spot.hand.heroIndex] = cards;
  }
  final board = [
    for (final c in spot.hand.board) CardModel(rank: c[0], suit: c.substring(1))
  ];
  final actions = spot.hand.actions.values.expand((l) => l).toList();
  final stacks = {
    for (int i = 0; i < spot.hand.playerCount; i++)
      i: spot.hand.stacks['$i']?.round() ?? 0
  };
  final positions = {
    for (int i = 0; i < spot.hand.playerCount; i++)
      i: i == spot.hand.heroIndex ? spot.hand.position.label : ''
  };
  String? gto;
  for (final a in spot.hand.actions[0] ?? []) {
    if (a.playerIndex == spot.hand.heroIndex) {
      gto = a.action.toUpperCase();
      break;
    }
  }
  int street = 0;
  if (board.length >= 5) {
    street = 3;
  } else if (board.length == 4) {
    street = 2;
  } else if (board.length >= 3) {
    street = 1;
  }
  return SavedHand(
    name: spot.title,
    spotId: spot.id,
    heroIndex: spot.hand.heroIndex,
    heroPosition: spot.hand.position.label,
    numberOfPlayers: spot.hand.playerCount,
    playerCards: playerCards,
    boardCards: board,
    boardStreet: street,
    actions: actions,
    stackSizes: stacks,
    anteBb: anteBb,
    playerPositions: positions,
    tags: List<String>.from(spot.tags),
    gtoAction: gto,
  );
}
