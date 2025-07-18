import '../models/card_model.dart';

/// Parses a token like `Ah` or `TD` into a [CardModel].
/// Returns `null` if the token is not valid.
CardModel? parseCard(String token) {
  if (token.length < 2) return null;
  final rank = token.substring(0, token.length - 1).toUpperCase();
  final suitChar = token[token.length - 1].toLowerCase();
  switch (suitChar) {
    case 'h':
      return CardModel(rank: rank, suit: '♥');
    case 'd':
      return CardModel(rank: rank, suit: '♦');
    case 'c':
      return CardModel(rank: rank, suit: '♣');
    case 's':
      return CardModel(rank: rank, suit: '♠');
  }
  return null;
}
