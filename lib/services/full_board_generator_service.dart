import 'dart:math';

import '../models/board.dart';
import '../models/card_model.dart';
import 'board_texture_filter_service.dart';
import 'card_deck_service.dart';

class FullBoardRequest {
  final int stages; // 3=flop, 4=turn, 5=river
  final List<CardModel> excludedCards;
  final Map<String, dynamic>? boardFilterParams;

  FullBoardRequest({
    required this.stages,
    this.excludedCards = const [],
    this.boardFilterParams,
  });
}

typedef BoardResult = Board;

class FullBoardGeneratorService {
  FullBoardGeneratorService({
    Random? random,
    CardDeckService? deckService,
    BoardTextureFilterService? textureFilter,
  }) : _random = random ?? Random(),
       _deckService = deckService ?? const CardDeckService(),
       _textureFilter = textureFilter ?? const BoardTextureFilterService();

  final Random _random;
  final CardDeckService _deckService;
  final BoardTextureFilterService _textureFilter;

  BoardResult generateBoard(FullBoardRequest request) {
    if (request.stages < 3 || request.stages > 5) {
      throw ArgumentError('stages must be between 3 and 5');
    }
    const maxAttempts = 10000;
    final boardFilterParams = request.boardFilterParams;
    final deck = _buildDeck(request.excludedCards, boardFilterParams);
    final requiredRanks = <String>[
      ...(boardFilterParams?['requiredRanks'] as List? ?? []).map(
        (e) => e.toString().toUpperCase(),
      ),
    ];
    final requiredSuits = <String>[
      ...(boardFilterParams?['requiredSuits'] as List? ?? []).map(
        (e) => e.toString(),
      ),
    ];
    for (var i = 0; i < maxAttempts; i++) {
      deck.shuffle(_random);
      final cards = deck.take(5).toList();
      final partial = cards.sublist(0, request.stages);
      if (requiredRanks.any(
        (r) => !partial.any((c) => c.rank.toUpperCase() == r),
      )) {
        continue;
      }
      if (requiredSuits.any((s) => !partial.any((c) => c.suit == s))) {
        continue;
      }
      if (_textureFilter.isMatch(partial, boardFilterParams)) {
        return Board(
          flop: cards.sublist(0, 3),
          turn: request.stages >= 4 ? cards[3] : null,
          river: request.stages == 5 ? cards[4] : null,
        );
      }
    }
    throw StateError('Unable to generate board with given filter');
  }

  BoardResult generateFullBoard({
    List<CardModel> excludedCards = const [],
    Map<String, dynamic>? boardFilterParams,
  }) => generateBoard(
    FullBoardRequest(
      stages: 5,
      excludedCards: excludedCards,
      boardFilterParams: boardFilterParams,
    ),
  );

  BoardResult generatePartialBoard({
    required int stages,
    List<CardModel> excludedCards = const [],
    Map<String, dynamic>? boardFilterParams,
  }) => generateBoard(
    FullBoardRequest(
      stages: stages,
      excludedCards: excludedCards,
      boardFilterParams: boardFilterParams,
    ),
  );

  List<CardModel> _buildDeck(
    List<CardModel> excludedCards,
    Map<String, dynamic>? boardFilterParams,
  ) {
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
