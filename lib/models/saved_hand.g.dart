part of 'saved_hand.dart';

SavedHand _$SavedHandFromJson(Map<String, dynamic> json) => SavedHand(
  name: json['name'] as String? ?? '',
  heroIndex: json['heroIndex'] as int? ?? 0,
  heroPosition: json['heroPosition'] as String? ?? '',
  numberOfPlayers: json['numberOfPlayers'] as int? ?? 0,
  playerCards: const [],
  boardCards: const [],
  boardStreet: json['boardStreet'] as int? ?? 0,
  stackSizes: const {},
  actions: const [],
  playerPositions: const {},
  revealedCards: const [],
);

Map<String, dynamic> _$SavedHandToJson(SavedHand instance) =>
    <String, dynamic>{};
