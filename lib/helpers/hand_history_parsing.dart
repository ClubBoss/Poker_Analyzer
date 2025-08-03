import '../models/card_model.dart';

/// Map of single-letter suit identifiers to their symbol representations.
const Map<String, String> suits = {
  'h': '♥',
  'd': '♦',
  'c': '♣',
  's': '♠',
};

/// Parses a token like `Ah` or `TD` into a [CardModel].
/// Returns `null` if the token is not valid.
CardModel? parseCard(String token) {
  if (token.length < 2) return null;
  final rank = token.substring(0, token.length - 1).toUpperCase();
  final suitChar = token[token.length - 1].toLowerCase();
  final suit = suits[suitChar];
  if (suit == null) return null;
  return CardModel(rank: rank, suit: suit);
}
