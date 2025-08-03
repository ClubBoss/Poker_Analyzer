import 'dart:math';

import '../models/training_spot.dart';
import '../models/card_model.dart';
import '../models/action_entry.dart';
import '../models/player_model.dart';
import 'hand_range_library.dart';
import 'board_texture_filter_service.dart';

class SpotGenerationParams {
  final String position;
  final String villainAction;
  final List<String> handGroup;
  final int count;
  final Map<String, dynamic>? boardFilter;
  final String targetStreet;

  SpotGenerationParams({
    required this.position,
    required this.villainAction,
    required this.handGroup,
    required this.count,
    this.boardFilter,
    this.targetStreet = 'flop',
  });
}

class TrainingSpotGeneratorService {
  TrainingSpotGeneratorService({Random? random}) : _random = random ?? Random();

  final Random _random;
  static const List<String> _positions6max = ['utg', 'hj', 'co', 'btn', 'sb', 'bb'];

  List<TrainingSpot> generate(SpotGenerationParams params) {
    final pool = <String>{};
    for (final g in params.handGroup) {
      pool.addAll(HandRangeLibrary.getGroup(g));
    }
    final hands = pool.toList()..shuffle(_random);

    final used = <String>{};
    final spots = <TrainingSpot>[];
    for (final h in hands) {
      if (spots.length >= params.count) break;
      if (!used.add(h)) continue;
      spots.add(_buildSpot(h, params));
    }
    return spots;
  }

  TrainingSpot _buildSpot(String hand, SpotGenerationParams params) {
    var idx = _positions6max.indexOf(params.position.toLowerCase());
    if (idx < 0) idx = 0;
    final playerCards = List.generate(6, (_) => <CardModel>[]);
    playerCards[idx] = _cardsForHand(hand);

    final allPlayerCards = playerCards.expand((e) => e).toList();
    final board = generateRandomBoard(
      street: params.targetStreet,
      boardFilter: params.boardFilter,
      excludedCards: allPlayerCards,
    );

    final villain = (idx + 1) % 6;
    final parts = params.villainAction.split(' ');
    final action = parts.isNotEmpty ? parts.first : params.villainAction;
    final amount = parts.length > 1 ? double.tryParse(parts[1]) : null;

    final actions = [ActionEntry(0, villain, action, amount: amount)];
    return TrainingSpot(
      playerCards: playerCards,
      boardCards: board,
      actions: actions,
      heroIndex: idx,
      numberOfPlayers: 6,
      playerTypes: List.filled(6, PlayerType.unknown),
      positions: List.of(_positions6max),
      stacks: List.filled(6, 100),
      actionType: SpotActionType.pushFold,
      heroPosition: _positions6max[idx],
      villainPosition: _positions6max[villain],
    );
  }

  List<CardModel> _cardsForHand(String hand) {
    const suits = ['♠', '♥', '♦', '♣'];
    if (hand.length == 2) {
      final r = hand[0];
      final s1 = suits[_random.nextInt(4)];
      var s2 = suits[_random.nextInt(4)];
      while (s2 == s1) {
        s2 = suits[_random.nextInt(4)];
      }
      return [CardModel(rank: r, suit: s1), CardModel(rank: r, suit: s2)];
    }
    final r1 = hand[0];
    final r2 = hand[1];
    final suited = hand[2] == 's';
    if (suited) {
      final s = suits[_random.nextInt(4)];
      return [CardModel(rank: r1, suit: s), CardModel(rank: r2, suit: s)];
    }
    final s1 = suits[_random.nextInt(4)];
    var s2 = suits[_random.nextInt(4)];
    while (s2 == s1) {
      s2 = suits[_random.nextInt(4)];
    }
    return [CardModel(rank: r1, suit: s1), CardModel(rank: r2, suit: s2)];
  }

  List<CardModel> generateRandomBoard({
    required String street,
    Map<String, dynamic>? boardFilter,
    List<CardModel> excludedCards = const [],
  }) {
    final cardsNeeded = street == 'river'
        ? 5
        : street == 'turn'
            ? 4
            : 3;

    const ranks = ['A', 'K', 'Q', 'J', 'T', '9', '8', '7', '6', '5', '4', '3', '2'];
    const suits = ['♠', '♥', '♦', '♣'];

    final excludedRanks = <String>{
      for (final r in (boardFilter?['excludedRanks'] as List? ?? []))
        r.toString().toUpperCase(),
    };

    final requiredRanks = <String>[...
      (boardFilter?['requiredRanks'] as List? ?? [])
          .map((e) => e.toString().toUpperCase())
    ];
    final requiredSuits = <String>[...
      (boardFilter?['requiredSuits'] as List? ?? [])
          .map((e) => e.toString())
    ];

    final deck = <CardModel>[
      for (final r in ranks)
        if (!excludedRanks.contains(r))
          for (final s in suits) CardModel(rank: r, suit: s),
    ];

    deck.removeWhere((c) =>
        excludedCards.any((e) => e.rank == c.rank && e.suit == c.suit));

    final svc = const BoardTextureFilterService();
    for (var i = 0; i < 10000; i++) {
      deck.shuffle(_random);
      final board = deck.take(cardsNeeded).toList();
      if (requiredRanks.any((r) => !board.any((c) => c.rank == r))) {
        continue;
      }
      if (requiredSuits.any((s) => !board.any((c) => c.suit == s))) {
        continue;
      }
      if (svc.isMatch(board, boardFilter)) {
        return board;
      }
    }
    throw StateError('Unable to generate board with given filter');
  }

  List<CardModel> generateRandomFlop({
    Map<String, dynamic>? boardFilter,
    List<CardModel> excludedCards = const [],
  }) =>
      generateRandomBoard(
        street: 'flop',
        boardFilter: boardFilter,
        excludedCards: excludedCards,
      );
}

