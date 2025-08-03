import 'dart:math';

import '../models/board.dart';
import '../models/card_model.dart';
import 'board_texture_filter_service.dart';
import 'card_deck_service.dart';

class FullBoardGeneratorService {
  FullBoardGeneratorService({
    Random? random,
    CardDeckService? deckService,
    BoardTextureFilterService? textureFilter,
  })  : _random = random ?? Random(),
        _deckService = deckService ?? const CardDeckService(),
        _textureFilter = textureFilter ?? const BoardTextureFilterService();

  final Random _random;
  final CardDeckService _deckService;
  final BoardTextureFilterService _textureFilter;

  Board generateFullBoard({
    List<CardModel> excludedCards = const [],
    Map<String, dynamic>? boardFilterParams,
    int maxAttempts = 10000,
  }) =>
      generatePartialBoard(
        stages: 5,
        excludedCards: excludedCards,
        boardFilterParams: boardFilterParams,
        maxAttempts: maxAttempts,
      );

  Board generatePartialBoard({
    required int stages,
    List<CardModel> excludedCards = const [],
    Map<String, dynamic>? boardFilterParams,
    int maxAttempts = 10000,
  }) {
    if (stages < 3 || stages > 5) {
      throw ArgumentError('stages must be between 3 and 5');
    }
    final deck = _buildDeck(excludedCards, boardFilterParams);
    final requiredRanks = <String>[...
      (boardFilterParams?['requiredRanks'] as List? ?? [])
          .map((e) => e.toString().toUpperCase()),
    ];
    final requiredSuits = <String>[...
      (boardFilterParams?['requiredSuits'] as List? ?? [])
          .map((e) => e.toString()),
    ];
    for (var i = 0; i < maxAttempts; i++) {
      deck.shuffle(_random);
      final cards = deck.take(5).toList();
      final partial = cards.sublist(0, stages);
      if (requiredRanks.any((r) => !partial.any((c) => c.rank.toUpperCase() == r))) {
        continue;
      }
      if (requiredSuits.any((s) => !partial.any((c) => c.suit == s))) {
        continue;
      }
      if (_textureFilter.isMatch(partial, boardFilterParams)) {
        return Board(
          flop: cards.sublist(0, 3),
          turn: stages >= 4 ? cards[3] : null,
          river: stages == 5 ? cards[4] : null,
        );
      }
    }
    throw StateError('Unable to generate board with given filter');
  }

  List<CardModel> _buildDeck(
      List<CardModel> excludedCards, Map<String, dynamic>? boardFilterParams) {
    final excludedRanks = <String>{
      for (final r in (boardFilterParams?['excludedRanks'] as List? ?? []))
        r.toString().toUpperCase(),
    };
    return _deckService.buildDeck(
      excludedCards: excludedCards,
      excludedRanks: excludedRanks,
    );
  }
}

