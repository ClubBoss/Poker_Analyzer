import 'dart:math';

import '../models/full_board.dart';
import '../models/card_model.dart';
import '../helpers/board_filtering_params_builder.dart';
import 'card_deck_service.dart';
import 'board_texture_filter_service.dart';
import 'board_filtering_service_v2.dart';

class FullBoardGenerator {
  FullBoardGenerator({
    Random? random,
    CardDeckService? deckService,
    BoardTextureFilterService? textureFilter,
    BoardFilteringServiceV2? boardFilter,
  })  : _random = random ?? Random(),
        _deckService = deckService ?? const CardDeckService(),
        _textureFilter = textureFilter ?? const BoardTextureFilterService(),
        _boardFilter = boardFilter ?? const BoardFilteringServiceV2();

  final Random _random;
  final CardDeckService _deckService;
  final BoardTextureFilterService _textureFilter;
  final BoardFilteringServiceV2 _boardFilter;

  int lastAttempts = 0;

  FullBoard generate({
    Map<String, dynamic>? boardConstraints,
    String targetStreet = 'full',
    List<CardModel> excludedCards = const [],
  }) {
    final constraints = boardConstraints ?? {};
    final tags = <String>[];
    final requiredRanks = <String>[
      for (final r in (constraints['requiredRanks'] as List? ?? []))
        r.toString().toUpperCase(),
    ];
    final requiredSuits = <String>[
      for (final s in (constraints['requiredSuits'] as List? ?? []))
        s.toString(),
    ];

    final texture = constraints['texture'];
    if (texture != null) tags.add(texture.toString());
    if (constraints['rainbow'] == true) tags.add('rainbow');
    if (constraints['broadwayHeavy'] == true) tags.add('broadway');
    if (constraints['drawy'] == true) tags.add('connected');
    if (constraints['low'] == true) tags.add('low');
    if (constraints['paired'] == true) tags.add('paired');
    if (constraints['aceHigh'] == true) tags.add('aceHigh');

    final filter = BoardFilteringParamsBuilder.build(tags);
    if (requiredRanks.isNotEmpty) filter['requiredRanks'] = requiredRanks;
    if (requiredSuits.isNotEmpty) filter['requiredSuits'] = requiredSuits;

    final requiredTags = <String>{
      for (final t in (constraints['requiredTags'] as List? ?? []))
        t.toString(),
    };
    final excludedTags = <String>{
      for (final t in (constraints['excludedTags'] as List? ?? []))
        t.toString(),
    };

    final deck = _deckService.buildDeck(excludedCards: excludedCards);

    const maxAttempts = 10000;
    lastAttempts = 0;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      lastAttempts++;
      deck.shuffle(_random);
      final cards = <CardModel>[...deck];
      final flop = cards.sublist(0, 3);
      if (!_passesConstraints(flop, filter, requiredTags, excludedTags)) {
        continue;
      }
      if (targetStreet == 'flop') {
        return FullBoard(flop: flop);
      }
      final turn = cards[3];
      final flopTurn = [...flop, turn];
      if (!_passesConstraints(flopTurn, filter, requiredTags, excludedTags)) {
        continue;
      }
      if (targetStreet == 'turn') {
        return FullBoard(flop: flop, turn: turn);
      }
      final river = cards[4];
      final full = [...flopTurn, river];
      if (!_passesConstraints(full, filter, requiredTags, excludedTags)) {
        continue;
      }
      return FullBoard(flop: flop, turn: turn, river: river);
    }
    throw StateError('Unable to generate board with given constraints');
  }

  bool _passesConstraints(
    List<CardModel> board,
    Map<String, dynamic> filter,
    Set<String> requiredTags,
    Set<String> excludedTags,
  ) {
    if (!_textureFilter.isMatch(board, filter)) return false;
    if (requiredTags.isEmpty && excludedTags.isEmpty) return true;
    final tags = _evaluateTags(board);
    if (excludedTags.any(tags.contains)) return false;
    for (final t in requiredTags) {
      if (!tags.contains(t)) return false;
    }
    return true;
  }

  Set<String> _evaluateTags(List<CardModel> cards) {
    final tags = <String>{};
    final ranks = cards.map((c) => c.rank).toList();
    final suits = cards.map((c) => c.suit).toList();
    final values = cards.map((c) => _rankValue(c.rank)).toList();

    if (ranks.toSet().length < ranks.length) tags.add('paired');
    if (values.any((v) => v >= 10)) tags.add('highCard');
    if (values.any((v) => v == 14)) tags.add('aceHigh');
    if (values.every((v) => v <= 9)) tags.add('low');

    final broadwayCount = values.where((v) => v >= 10).length;
    if (broadwayCount >= 3) tags.add('broadwayHeavy');
    if (broadwayCount == 3) tags.add('tripleBroadway');

    final suitCounts = <String, int>{};
    for (final s in suits) {
      suitCounts[s] = (suitCounts[s] ?? 0) + 1;
    }
    if (suitCounts.values.any((c) => c >= 4)) {
      tags.add('fourToFlush');
      tags.add('flushDraw');
    }
    if (suitCounts.values.any((c) => c == 5)) {
      tags.add('flush');
    }

    if (_isStraightDrawHeavy(values)) tags.add('straightDrawHeavy');

    return tags;
  }

  bool _isStraightDrawHeavy(List<int> values) {
    if (values.length < 3) return false;
    final sorted = [...values]..sort();
    return sorted.last - sorted.first <= 4;
  }

  int _rankValue(String r) {
    switch (r.toUpperCase()) {
      case 'A':
        return 14;
      case 'K':
        return 13;
      case 'Q':
        return 12;
      case 'J':
        return 11;
      case 'T':
        return 10;
      case '9':
        return 9;
      case '8':
        return 8;
      case '7':
        return 7;
      case '6':
        return 6;
      case '5':
        return 5;
      case '4':
        return 4;
      case '3':
        return 3;
      case '2':
        return 2;
      default:
        return 0;
    }
  }
}
