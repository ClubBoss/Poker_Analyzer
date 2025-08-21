import 'action_entry.dart';
import 'card_model.dart';
import 'player_model.dart';
import 'saved_hand.dart';
import 'spot_model.dart';

enum SpotActionType { pushFold, callPush }

class TrainingSpot implements SpotModel {
  final List<List<CardModel>> playerCards;
  final List<CardModel> boardCards;
  final List<ActionEntry> actions;
  final int heroIndex;
  final int numberOfPlayers;
  final List<PlayerType> playerTypes;
  final List<String> positions;
  final List<int> stacks;

  /// Optional strategy advice for each player indexed by player position.
  final List<String>? strategyAdvice;

  /// Optional equity values for each player as percentages.
  final List<double>? equities;

  /// Optional hero range matrix [13x13] with frequencies 0.0-1.0.
  final List<List<double>>? rangeMatrix;
  final String? tournamentId;
  final int? buyIn;
  final int? totalPrizePool;
  final int? numberOfEntrants;
  final String? gameType;
  final int anteBb;
  final String? category;
  @override
  final List<String> tags;
  final List<String> inlineLessons;
  final int difficulty;
  final int rating;
  final String? userAction;
  final String? userComment;
  final String? actionHistory;
  final String? recommendedAction;
  final int? recommendedAmount;
  final SpotActionType actionType;
  final String? heroPosition;
  final String? villainPosition;
  final int? heroStack;
  final int? villainStack;
  final double? expectedValue;
  final DateTime createdAt;

  TrainingSpot({
    required this.playerCards,
    required this.boardCards,
    required this.actions,
    required this.heroIndex,
    required this.numberOfPlayers,
    required this.playerTypes,
    required this.positions,
    required this.stacks,
    this.strategyAdvice,
    this.equities,
    this.rangeMatrix,
    this.tournamentId,
    this.buyIn,
    this.totalPrizePool,
    this.numberOfEntrants,
    this.gameType,
    this.anteBb = 0,
    this.category,
    List<String>? tags,
    this.userAction,
    this.userComment,
    this.actionHistory,
    this.recommendedAction,
    this.recommendedAmount,
    this.actionType = SpotActionType.pushFold,
    this.heroPosition,
    this.villainPosition,
    this.heroStack,
    this.villainStack,
    this.expectedValue,
    this.difficulty = 3,
    this.rating = 0,
    List<String>? inlineLessons,
    DateTime? createdAt,
  })  : tags = tags ?? [],
        inlineLessons = inlineLessons ?? [],
        createdAt = createdAt ?? DateTime.now();

  factory TrainingSpot.fromSavedHand(SavedHand hand) {
    return TrainingSpot(
      playerCards: [
        for (final list in hand.playerCards) List<CardModel>.from(list),
      ],
      boardCards: List<CardModel>.from(hand.boardCards),
      actions: List<ActionEntry>.from(hand.actions),
      heroIndex: hand.heroIndex,
      numberOfPlayers: hand.numberOfPlayers,
      playerTypes: [
        for (int i = 0; i < hand.numberOfPlayers; i++)
          hand.playerTypes?[i] ?? PlayerType.unknown,
      ],
      positions: [
        for (int i = 0; i < hand.numberOfPlayers; i++)
          hand.playerPositions[i] ?? '',
      ],
      stacks: [
        for (int i = 0; i < hand.numberOfPlayers; i++) hand.stackSizes[i] ?? 0,
      ],
      rangeMatrix: null,
      equities: null,
      tournamentId: hand.tournamentId,
      buyIn: hand.buyIn,
      totalPrizePool: hand.totalPrizePool,
      numberOfEntrants: hand.numberOfEntrants,
      gameType: hand.gameType,
      anteBb: hand.anteBb,
      category: hand.category,
      tags: List<String>.from(hand.tags),
      userAction: null,
      userComment: hand.comment,
      actionHistory: null,
      difficulty: 3,
      rating: hand.rating,
      createdAt: hand.date,
      heroPosition: hand.heroPosition,
      heroStack: hand.stackSizes[hand.heroIndex],
      villainStack: hand.stackSizes[hand.heroIndex == 0 ? 1 : 0],
      villainPosition: hand.playerPositions[hand.heroIndex == 0 ? 1 : 0] ?? '',
      actionType: SpotActionType.pushFold,
    );
  }

  Map<String, dynamic> toJson() => {
        'playerCards': [
          for (final list in playerCards)
            [
              for (final c in list) {'rank': c.rank, 'suit': c.suit},
            ],
        ],
        'boardCards': [
          for (final c in boardCards) {'rank': c.rank, 'suit': c.suit},
        ],
        'actions': [
          for (final a in actions)
            {
              'street': a.street,
              'playerIndex': a.playerIndex,
              'action': a.action,
              if (a.amount != null) 'amount': a.amount,
              if (a.manualEvaluation != null)
                'manualEvaluation': a.manualEvaluation,
              if (a.customLabel != null) 'customLabel': a.customLabel,
            },
        ],
        'heroIndex': heroIndex,
        'numberOfPlayers': numberOfPlayers,
        'playerTypes': [for (final t in playerTypes) t.name],
        'positions': positions,
        'stacks': stacks,
        if (equities != null) 'equities': equities,
        if (rangeMatrix != null) 'rangeMatrix': rangeMatrix,
        if (tournamentId != null) 'tournamentId': tournamentId,
        if (buyIn != null) 'buyIn': buyIn,
        if (totalPrizePool != null) 'totalPrizePool': totalPrizePool,
        if (numberOfEntrants != null) 'numberOfEntrants': numberOfEntrants,
        if (gameType != null) 'gameType': gameType,
        'anteBb': anteBb,
        if (category != null) 'category': category,
        if (tags.isNotEmpty) 'tags': tags,
        if (inlineLessons.isNotEmpty) 'inlineLessons': inlineLessons,
        if (strategyAdvice != null) 'strategyAdvice': strategyAdvice,
        'difficulty': difficulty,
        'rating': rating,
        if (userAction != null) 'userAction': userAction,
        if (userComment != null) 'userComment': userComment,
        if (actionHistory != null) 'actionHistory': actionHistory,
        if (recommendedAction != null) 'recommendedAction': recommendedAction,
        if (recommendedAmount != null) 'recommendedAmount': recommendedAmount,
        'actionType': actionType.name,
        if (heroPosition != null) 'heroPosition': heroPosition,
        if (villainPosition != null) 'villainPosition': villainPosition,
        if (heroStack != null) 'heroStack': heroStack,
        if (villainStack != null) 'villainStack': villainStack,
        if (expectedValue != null) 'expectedValue': expectedValue,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TrainingSpot.fromJson(Map<String, dynamic> json) {
    final pcData = json['playerCards'] as List? ?? [];
    final pc = <List<CardModel>>[];
    for (final list in pcData) {
      if (list is List) {
        pc.add([
          for (final c in list)
            CardModel(rank: c['rank'] as String, suit: c['suit'] as String),
        ]);
      } else {
        pc.add([]);
      }
    }

    final board = <CardModel>[];
    for (final c in (json['boardCards'] as List? ?? [])) {
      if (c is Map) {
        board.add(
          CardModel(rank: c['rank'] as String, suit: c['suit'] as String),
        );
      }
    }

    final acts = <ActionEntry>[];
    for (final a in (json['actions'] as List? ?? [])) {
      if (a is Map) {
        acts.add(
          ActionEntry(
            a['street'] as int,
            a['playerIndex'] as int,
            a['action'] as String,
            amount: (a['amount'] as num?)?.toDouble(),
            manualEvaluation: a['manualEvaluation'] as String?,
            customLabel: a['customLabel'] as String?,
          ),
        );
      }
    }

    final heroIndex = json['heroIndex'] as int? ?? 0;
    final numberOfPlayers = json['numberOfPlayers'] as int? ?? pc.length;

    final types = <PlayerType>[];
    final typesData = (json['playerTypes'] as List?)?.cast<String>() ?? [];
    for (int i = 0; i < numberOfPlayers; i++) {
      if (i < typesData.length) {
        types.add(
          PlayerType.values.firstWhere(
            (e) => e.name == typesData[i],
            orElse: () => PlayerType.unknown,
          ),
        );
      } else {
        types.add(PlayerType.unknown);
      }
    }

    final posData = (json['positions'] as List?)?.cast<String>() ?? [];
    final positions = <String>[];
    for (int i = 0; i < numberOfPlayers; i++) {
      positions.add(i < posData.length ? posData[i] : '');
    }

    final stackData = (json['stacks'] as List?)?.cast<num>() ?? [];
    final stacks = <int>[];
    for (int i = 0; i < numberOfPlayers; i++) {
      stacks.add(i < stackData.length ? stackData[i].toInt() : 0);
    }

    final adviceData = (json['strategyAdvice'] as List?)?.cast<String>();
    final equityData = (json['equities'] as List?)?.cast<num>();
    final rangeData = json['rangeMatrix'] as List?;
    List<double>? equities;
    if (equityData != null) {
      equities = [for (final e in equityData) e.toDouble()];
    }
    List<List<double>>? rangeMatrix;
    if (rangeData != null) {
      rangeMatrix = [];
      for (final row in rangeData) {
        if (row is List) {
          rangeMatrix.add([
            for (final v in row) (v as num?)?.toDouble() ?? 0.0,
          ]);
        }
      }
    }

    return TrainingSpot(
      playerCards: pc,
      boardCards: board,
      actions: acts,
      heroIndex: heroIndex,
      numberOfPlayers: numberOfPlayers,
      playerTypes: types,
      positions: positions,
      stacks: stacks,
      strategyAdvice: adviceData,
      equities: equities,
      rangeMatrix: rangeMatrix,
      tournamentId: json['tournamentId'] as String?,
      buyIn: (json['buyIn'] as num?)?.toInt(),
      totalPrizePool: (json['totalPrizePool'] as num?)?.toInt(),
      numberOfEntrants: (json['numberOfEntrants'] as num?)?.toInt(),
      gameType: json['gameType'] as String?,
      anteBb: json['anteBb'] as int? ?? 0,
      category: json['category'] as String?,
      tags: [for (final t in (json['tags'] as List? ?? [])) t as String],
      inlineLessons: [
        for (final t in (json['inlineLessons'] as List? ?? [])) t as String,
      ],
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 3,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      userAction: json['userAction'] as String?,
      userComment: json['userComment'] as String?,
      actionHistory: json['actionHistory'] as String?,
      recommendedAction: json['recommendedAction'] as String?,
      recommendedAmount: (json['recommendedAmount'] as num?)?.toInt(),
      actionType: SpotActionType.values.firstWhere(
        (e) => e.name == json['actionType'],
        orElse: () => SpotActionType.pushFold,
      ),
      heroPosition: json['heroPosition'] as String?,
      villainPosition: json['villainPosition'] as String?,
      heroStack: (json['heroStack'] as num?)?.toInt(),
      villainStack: (json['villainStack'] as num?)?.toInt(),
      expectedValue: (json['expectedValue'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  TrainingSpot copyWith({
    int? difficulty,
    int? rating,
    List<String>? tags,
    String? category,
    String? userAction,
    String? userComment,
    String? actionHistory,
    String? recommendedAction,
    int? recommendedAmount,
    SpotActionType? actionType,
    String? heroPosition,
    String? villainPosition,
    int? heroStack,
    int? villainStack,
    double? expectedValue,
    List<String>? strategyAdvice,
    List<double>? equities,
    List<List<double>>? rangeMatrix,
    DateTime? createdAt,
    int? anteBb,
    List<String>? inlineLessons,
  }) {
    return TrainingSpot(
      playerCards: [for (final list in playerCards) List<CardModel>.from(list)],
      boardCards: List<CardModel>.from(boardCards),
      actions: List<ActionEntry>.from(actions),
      heroIndex: heroIndex,
      numberOfPlayers: numberOfPlayers,
      playerTypes: List<PlayerType>.from(playerTypes),
      positions: List<String>.from(positions),
      stacks: List<int>.from(stacks),
      strategyAdvice: strategyAdvice ?? this.strategyAdvice,
      equities: equities ?? this.equities,
      rangeMatrix: rangeMatrix ?? this.rangeMatrix,
      tournamentId: tournamentId,
      buyIn: buyIn,
      totalPrizePool: totalPrizePool,
      numberOfEntrants: numberOfEntrants,
      gameType: gameType,
      anteBb: anteBb ?? this.anteBb,
      category: category ?? this.category,
      tags: tags ?? List<String>.from(this.tags),
      inlineLessons: inlineLessons ?? List<String>.from(this.inlineLessons),
      difficulty: difficulty ?? this.difficulty,
      rating: rating ?? this.rating,
      userAction: userAction ?? this.userAction,
      userComment: userComment ?? this.userComment,
      actionHistory: actionHistory ?? this.actionHistory,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      recommendedAmount: recommendedAmount ?? this.recommendedAmount,
      actionType: actionType ?? this.actionType,
      heroPosition: heroPosition ?? this.heroPosition,
      villainPosition: villainPosition ?? this.villainPosition,
      heroStack: heroStack ?? this.heroStack,
      villainStack: villainStack ?? this.villainStack,
      expectedValue: expectedValue ?? this.expectedValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  TrainingSpot copy() {
    return TrainingSpot.fromJson(toJson());
  }
}
