import 'dart:math';

import '../models/full_board.dart';
import '../models/card_model.dart';
import '../helpers/board_filtering_params_builder.dart';
import 'card_deck_service.dart';
import 'board_texture_filter_service.dart';
import 'board_filtering_service_v2.dart';
import 'board_texture_classifier.dart';

class FullBoardGenerator {
  FullBoardGenerator({
    Random? random,
    CardDeckService? deckService,
    BoardTextureFilterService? textureFilter,
    BoardFilteringServiceV2? boardFilter,
    BoardTextureClassifier? classifier,
  })  : _random = random ?? Random(),
        _deckService = deckService ?? const CardDeckService(),
        _textureFilter = textureFilter ?? const BoardTextureFilterService(),
        _boardFilter = boardFilter ?? const BoardFilteringServiceV2(),
        _classifier = classifier ?? const BoardTextureClassifier();

  final Random _random;
  final CardDeckService _deckService;
  final BoardTextureFilterService _textureFilter;
  final BoardFilteringServiceV2 _boardFilter;
  final BoardTextureClassifier _classifier;

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
        final tags = _classifier.classifyCards(flop);
        return FullBoard(flop: flop, textureTags: tags);
      }
      final turn = cards[3];
      final flopTurn = [...flop, turn];
      if (!_passesConstraints(flopTurn, filter, requiredTags, excludedTags)) {
        continue;
      }
      if (targetStreet == 'turn') {
        final tags = _classifier.classifyCards(flopTurn);
        return FullBoard(flop: flop, turn: turn, textureTags: tags);
      }
      final river = cards[4];
      final full = [...flopTurn, river];
      if (!_passesConstraints(full, filter, requiredTags, excludedTags)) {
        continue;
      }
      final tags = _classifier.classifyCards(full);
      return FullBoard(flop: flop, turn: turn, river: river, textureTags: tags);
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

  Set<String> _evaluateTags(List<CardModel> cards) =>
      _classifier.classifyCards(cards);
}
