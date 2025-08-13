import '../models/card_model.dart';

class CardDeckService {
  const CardDeckService();

  List<CardModel> buildDeck({
    List<CardModel> excludedCards = const [],
    Set<String> excludedRanks = const {},
  }) {
    const ranks = [
      'A',
      'K',
      'Q',
      'J',
      'T',
      '9',
      '8',
      '7',
      '6',
      '5',
      '4',
      '3',
      '2'
    ];
    const suits = ['♠', '♥', '♦', '♣'];
    final deck = <CardModel>[
      for (final r in ranks)
        if (!excludedRanks.contains(r))
          for (final s in suits) CardModel(rank: r, suit: s),
    ];
    deck.removeWhere(
        (c) => excludedCards.any((e) => e.rank == c.rank && e.suit == c.suit));
    return deck;
  }
}
