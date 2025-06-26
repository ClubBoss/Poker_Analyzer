import 'card_model.dart';
import 'action_entry.dart';
import 'player_model.dart';
import 'action_evaluation_request.dart';

class SavedHand {
  final String name;
  final int heroIndex;
  final String heroPosition;
  final int numberOfPlayers;
  final List<List<CardModel>> playerCards;
  final List<CardModel> boardCards;
  /// Revealed cards for each player. Empty lists if unknown.
  final List<List<CardModel>> revealedCards;
  final int? opponentIndex;
  final int? activePlayerIndex;
  final List<ActionEntry> actions;
  /// Street the board was showing when the hand was saved.
  final int boardStreet;
  /// Tournament identifier if the hand comes from a tournament.
  final String? tournamentId;
  /// Buy-in amount in whole currency units if available.
  final int? buyIn;
  /// Total prize pool in whole currency units if available.
  final int? totalPrizePool;
  /// Number of entrants in the tournament if known.
  final int? numberOfEntrants;
  /// Game type description such as "Hold'em No Limit".
  final String? gameType;
  /// Custom category label for this hand.
  final String? category;
  final Map<int, int> stackSizes;
  final Map<int, int>? currentBets;
  final Map<int, int>? remainingStacks;
  /// Winnings collected by each player in chips or big blinds.
  final Map<int, int>? winnings;
  /// Total pot size in chips or big blinds.
  final int? totalPot;
  /// Rake taken from the pot in chips or big blinds.
  final int? rake;
  final Map<int, String> playerPositions;
  final Map<int, PlayerType>? playerTypes;
  final String? comment;
  final List<String> tags;
  /// Rating given to this spot, from 1 to 5. 0 means unrated.
  final int rating;
  /// Cursor offset within the comment field when the hand was saved.
  final int? commentCursor;
  /// Cursor offset within the tags field when the hand was saved.
  final int? tagsCursor;
  final bool isFavorite;
  final int sessionId;
  final DateTime savedAt;
  final DateTime date;
  final String? expectedAction;
  /// Recommended action from GTO solver.
  final String? gtoAction;
  /// Predefined group label for hero hand range.
  final String? rangeGroup;
  final String? feedbackText;
  final double? evLoss;
  final Map<String, int>? effectiveStacksPerStreet;
  final Map<String, String>? validationNotes;
  final List<int>? collapsedHistoryStreets;
  final List<int>? firstActionTaken;
  final List<int>? foldedPlayers;
  final List<int>? allInPlayers;
  final Map<int, String?>? actionTags;
  /// Descriptions shown at showdown for each player.
  final Map<int, String>? showdownDescriptions;
  /// Finishing positions for players eliminated from a tournament.
  final Map<int, int>? eliminatedPositions;
  /// Pending action evaluation requests queued when the hand was saved.
  final List<ActionEvaluationRequest>? pendingEvaluations;
  /// Index in the action list used when the hand was last viewed.
  final int playbackIndex;
  /// Whether all board cards were revealed when the hand was saved.
  final bool showFullBoard;
  /// Street that was visible when the hand was saved.
  final int revealStreet;

  SavedHand({
    required this.name,
    required this.heroIndex,
    required this.heroPosition,
    required this.numberOfPlayers,
    required this.playerCards,
    required this.boardCards,
    required this.boardStreet,
    List<List<CardModel>>? revealedCards,
    this.opponentIndex,
    this.activePlayerIndex,
    required this.actions,
    required this.stackSizes,
    this.currentBets,
    this.remainingStacks,
    this.winnings,
    this.totalPot,
    this.rake,
    this.tournamentId,
    this.buyIn,
    this.totalPrizePool,
    this.numberOfEntrants,
    this.gameType,
    this.category,
    required this.playerPositions,
    this.playerTypes,
    this.comment,
    List<String>? tags,
    this.rating = 0,
    this.commentCursor,
    this.tagsCursor,
    this.isFavorite = false,
    this.sessionId = 0,
    DateTime? savedAt,
    DateTime? date,
    this.expectedAction,
    this.gtoAction,
    this.rangeGroup,
    this.feedbackText,
    this.evLoss,
    this.effectiveStacksPerStreet,
    this.validationNotes,
    this.collapsedHistoryStreets,
    this.firstActionTaken,
    this.foldedPlayers,
    this.allInPlayers,
    this.actionTags,
    this.showdownDescriptions,
    this.eliminatedPositions,
    this.pendingEvaluations,
    this.playbackIndex = 0,
    this.showFullBoard = false,
    int? revealStreet,
  })  : tags = tags ?? [],
        revealedCards = revealedCards ??
            List.generate(numberOfPlayers, (_) => <CardModel>[]),
        savedAt = savedAt ?? DateTime.now(),
        date = date ?? DateTime.now(),
        revealStreet = revealStreet ?? boardStreet;

  SavedHand copyWith({
    String? name,
    int? heroIndex,
    String? heroPosition,
    int? numberOfPlayers,
    List<List<CardModel>>? playerCards,
    List<CardModel>? boardCards,
    int? boardStreet,
    List<List<CardModel>>? revealedCards,
    int? opponentIndex,
    int? activePlayerIndex,
    List<ActionEntry>? actions,
    Map<int, int>? stackSizes,
    Map<int, int>? currentBets,
    Map<int, int>? remainingStacks,
    Map<int, int>? winnings,
    int? totalPot,
    int? rake,
    String? tournamentId,
    int? buyIn,
    int? totalPrizePool,
    int? numberOfEntrants,
    String? gameType,
    String? category,
    Map<int, String>? playerPositions,
    Map<int, PlayerType>? playerTypes,
    String? comment,
    List<String>? tags,
    int? rating,
    int? commentCursor,
    int? tagsCursor,
    bool? isFavorite,
    DateTime? savedAt,
    DateTime? date,
    String? expectedAction,
    String? gtoAction,
    String? rangeGroup,
    String? feedbackText,
    double? evLoss,
    Map<String, int>? effectiveStacksPerStreet,
    Map<String, String>? validationNotes,
    List<int>? collapsedHistoryStreets,
    List<int>? firstActionTaken,
    List<int>? foldedPlayers,
    List<int>? allInPlayers,
    Map<int, String?>? actionTags,
    Map<int, String>? showdownDescriptions,
    Map<int, int>? eliminatedPositions,
    List<ActionEvaluationRequest>? pendingEvaluations,
    int? playbackIndex,
    bool? showFullBoard,
    int? revealStreet,
    int? sessionId,
  }) {
    return SavedHand(
      name: name ?? this.name,
      heroIndex: heroIndex ?? this.heroIndex,
      heroPosition: heroPosition ?? this.heroPosition,
      numberOfPlayers: numberOfPlayers ?? this.numberOfPlayers,
      playerCards: playerCards ??
          [for (final list in this.playerCards) List<CardModel>.from(list)],
      boardCards: boardCards ?? List<CardModel>.from(this.boardCards),
      boardStreet: boardStreet ?? this.boardStreet,
      revealedCards: revealedCards ??
          [for (final list in this.revealedCards) List<CardModel>.from(list)],
      opponentIndex: opponentIndex ?? this.opponentIndex,
      activePlayerIndex: activePlayerIndex ?? this.activePlayerIndex,
      actions: actions ?? List<ActionEntry>.from(this.actions),
      stackSizes: stackSizes ?? Map<int, int>.from(this.stackSizes),
      currentBets: currentBets ??
          (this.currentBets == null ? null : Map<int, int>.from(this.currentBets!)),
      remainingStacks: remainingStacks ??
          (this.remainingStacks == null
              ? null
              : Map<int, int>.from(this.remainingStacks!)),
      winnings: winnings ??
          (this.winnings == null ? null : Map<int, int>.from(this.winnings!)),
      totalPot: totalPot ?? this.totalPot,
      rake: rake ?? this.rake,
      tournamentId: tournamentId ?? this.tournamentId,
      buyIn: buyIn ?? this.buyIn,
      totalPrizePool: totalPrizePool ?? this.totalPrizePool,
      numberOfEntrants: numberOfEntrants ?? this.numberOfEntrants,
      gameType: gameType ?? this.gameType,
      category: category ?? this.category,
      playerPositions: playerPositions ?? Map<int, String>.from(this.playerPositions),
      playerTypes: playerTypes ?? this.playerTypes,
      comment: comment ?? this.comment,
      tags: tags ?? List<String>.from(this.tags),
      rating: rating ?? this.rating,
      commentCursor: commentCursor ?? this.commentCursor,
      tagsCursor: tagsCursor ?? this.tagsCursor,
      isFavorite: isFavorite ?? this.isFavorite,
      sessionId: sessionId ?? this.sessionId,
      savedAt: savedAt ?? this.savedAt,
      date: date ?? this.date,
      expectedAction: expectedAction ?? this.expectedAction,
      gtoAction: gtoAction ?? this.gtoAction,
      rangeGroup: rangeGroup ?? this.rangeGroup,
      feedbackText: feedbackText ?? this.feedbackText,
      evLoss: evLoss ?? this.evLoss,
      effectiveStacksPerStreet:
          effectiveStacksPerStreet ?? this.effectiveStacksPerStreet,
      validationNotes: validationNotes ?? this.validationNotes,
      collapsedHistoryStreets:
          collapsedHistoryStreets ?? this.collapsedHistoryStreets,
      firstActionTaken: firstActionTaken ?? this.firstActionTaken,
      foldedPlayers: foldedPlayers ??
          (this.foldedPlayers == null
              ? null
              : List<int>.from(this.foldedPlayers!)),
      allInPlayers: allInPlayers ??
          (this.allInPlayers == null
              ? null
              : List<int>.from(this.allInPlayers!)),
      actionTags: actionTags ??
          (this.actionTags == null
              ? null
              : Map<int, String?>.from(this.actionTags!)),
      showdownDescriptions: showdownDescriptions ??
          (this.showdownDescriptions == null
              ? null
              : Map<int, String>.from(this.showdownDescriptions!)),
      eliminatedPositions: eliminatedPositions ??
          (this.eliminatedPositions == null
              ? null
              : Map<int, int>.from(this.eliminatedPositions!)),
      pendingEvaluations:
          pendingEvaluations ??
              (this.pendingEvaluations == null
                  ? null
                  : [
                      for (final e in this.pendingEvaluations!)
                        ActionEvaluationRequest(
                          id: e.id,
                          street: e.street,
                          playerIndex: e.playerIndex,
                          action: e.action,
                          amount: e.amount,
                          metadata: e.metadata == null
                              ? null
                              : Map<String, dynamic>.from(e.metadata!),
                          attempts: e.attempts,
                        )
                    ]),
      playbackIndex: playbackIndex ?? this.playbackIndex,
      showFullBoard: showFullBoard ?? this.showFullBoard,
      revealStreet: revealStreet ?? this.revealStreet,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'heroIndex': heroIndex,
        'heroPosition': heroPosition,
        'numberOfPlayers': numberOfPlayers,
        'playerCards': [
          for (final list in playerCards)
            [for (final c in list) {'rank': c.rank, 'suit': c.suit}]
        ],
        'boardCards': [for (final c in boardCards) {'rank': c.rank, 'suit': c.suit}],
        'revealedCards': [
          for (final list in revealedCards)
            [for (final c in list) {'rank': c.rank, 'suit': c.suit}]
        ],
        'boardStreet': boardStreet,
        if (opponentIndex != null) 'opponentIndex': opponentIndex,
        if (activePlayerIndex != null) 'activePlayerIndex': activePlayerIndex,
        'actions': [
          for (final a in actions)
            {
              'street': a.street,
              'playerIndex': a.playerIndex,
              'action': a.action,
              'amount': a.amount,
              'generated': a.generated,
              'timestamp': a.timestamp.toIso8601String(),
              if (a.manualEvaluation != null)
                'manualEvaluation': a.manualEvaluation,
            }
        ],
        'stackSizes': stackSizes.map((k, v) => MapEntry(k.toString(), v)),
        if (currentBets != null)
          'currentBets': currentBets!.map((k, v) => MapEntry(k.toString(), v)),
        if (remainingStacks != null)
          'remainingStacks':
              remainingStacks!.map((k, v) => MapEntry(k.toString(), v)),
        if (winnings != null)
          'winnings': winnings!.map((k, v) => MapEntry(k.toString(), v)),
        if (totalPot != null) 'totalPot': totalPot,
        if (rake != null) 'rake': rake,
        if (tournamentId != null) 'tournamentId': tournamentId,
        if (buyIn != null) 'buyIn': buyIn,
        if (totalPrizePool != null) 'totalPrizePool': totalPrizePool,
        if (numberOfEntrants != null) 'numberOfEntrants': numberOfEntrants,
        if (gameType != null) 'gameType': gameType,
        if (category != null) 'category': category,
        'playerPositions': playerPositions.map((k, v) => MapEntry(k.toString(), v)),
        if (playerTypes != null)
          'playerTypes':
              playerTypes!.map((k, v) => MapEntry(k.toString(), v.name)),
        if (comment != null) 'comment': comment,
        'tags': tags,
        'rating': rating,
        if (commentCursor != null) 'commentCursor': commentCursor,
        if (tagsCursor != null) 'tagsCursor': tagsCursor,
        'isFavorite': isFavorite,
        'sessionId': sessionId,
        'savedAt': savedAt.toIso8601String(),
        'date': date.toIso8601String(),
        if (expectedAction != null) 'expectedAction': expectedAction,
        if (gtoAction != null) 'gtoAction': gtoAction,
        if (rangeGroup != null) 'rangeGroup': rangeGroup,
        if (feedbackText != null) 'feedbackText': feedbackText,
        if (evLoss != null) 'evLoss': evLoss,
        if (effectiveStacksPerStreet != null)
          'effectiveStacksPerStreet': effectiveStacksPerStreet,
        if (validationNotes != null) 'validationNotes': validationNotes,
        if (collapsedHistoryStreets != null)
          'collapsedHistoryStreets': collapsedHistoryStreets,
        if (firstActionTaken != null)
          'firstActionTaken': firstActionTaken,
        if (foldedPlayers != null) 'foldedPlayers': foldedPlayers,
        if (allInPlayers != null) 'allInPlayers': allInPlayers,
        if (actionTags != null)
          'actionTags':
              actionTags!.map((k, v) => MapEntry(k.toString(), v)),
        if (showdownDescriptions != null)
          'showdownDescriptions':
              showdownDescriptions!.map((k, v) => MapEntry(k.toString(), v)),
        if (eliminatedPositions != null)
          'eliminatedPositions':
              eliminatedPositions!.map((k, v) => MapEntry(k.toString(), v)),
        if (pendingEvaluations != null)
          'pendingEvaluations': [for (final e in pendingEvaluations!) e.toJson()],
        'playbackIndex': playbackIndex,
        'showFullBoard': showFullBoard,
        'revealStreet': revealStreet,
      };

  factory SavedHand.fromJson(Map<String, dynamic> json) {
    List<List<CardModel>> pc = [];
    for (final list in (json['playerCards'] as List? ?? [])) {
      pc.add([
        for (final c in (list as List))
          CardModel(rank: c['rank'] as String, suit: c['suit'] as String)
      ]);
    }
    final board = [
      for (final c in (json['boardCards'] as List? ?? []))
        CardModel(rank: c['rank'] as String, suit: c['suit'] as String)
    ];
    final rc = [
      for (final list in (json['revealedCards'] as List? ?? []))
        [
          for (final c in (list as List))
            CardModel(rank: c['rank'] as String, suit: c['suit'] as String)
        ]
    ];
    final boardStreet = json['boardStreet'] as int? ?? 0;
    final oppIndex = json['opponentIndex'] as int?;
    final activeIndex = json['activePlayerIndex'] as int?;
    final acts = [
      for (final a in (json['actions'] as List? ?? []))
        ActionEntry(
          a['street'] as int,
          a['playerIndex'] as int,
          a['action'] as String,
          amount: a['amount'] as int?,
          generated: a['generated'] as bool? ?? false,
          timestamp:
              DateTime.tryParse(a['timestamp'] as String? ?? '') ?? DateTime.now(),
          manualEvaluation: a['manualEvaluation'] as String?,
        )
    ];
    final stack = <int, int>{};
    (json['stackSizes'] as Map? ?? {}).forEach((key, value) {
      stack[int.parse(key as String)] = value as int;
    });
    Map<int, int>? bets;
    if (json['currentBets'] != null) {
      bets = <int, int>{};
      (json['currentBets'] as Map).forEach((key, value) {
        bets![int.parse(key as String)] = value as int;
      });
    }
    Map<int, int>? remaining;
    if (json['remainingStacks'] != null) {
      remaining = <int, int>{};
      (json['remainingStacks'] as Map).forEach((key, value) {
        remaining![int.parse(key as String)] = value as int;
      });
    }
    Map<int, int>? wins;
    if (json['winnings'] != null) {
      wins = <int, int>{};
      (json['winnings'] as Map).forEach((key, value) {
        wins![int.parse(key as String)] = value as int;
      });
    }
    final totalPot = json['totalPot'] as int?;
    final rake = json['rake'] as int?;
    final tournamentId = json['tournamentId'] as String?;
    final buyIn = json['buyIn'] as int?;
    final totalPrizePool = json['totalPrizePool'] as int?;
    final numberOfEntrants = json['numberOfEntrants'] as int?;
    final gameType = json['gameType'] as String?;
    final category = json['category'] as String?;
    final positions = <int, String>{};
    (json['playerPositions'] as Map? ?? {}).forEach((key, value) {
      positions[int.parse(key as String)] = value as String;
    });
    final tags = [for (final t in (json['tags'] as List? ?? [])) t as String];
    final rating = (json['rating'] as num?)?.toInt() ?? 0;
    final isFavorite = json['isFavorite'] as bool? ?? false;
    final sessionId = json['sessionId'] as int? ?? 0;
    final savedAt =
        DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now();
    final date = DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now();
    Map<String, int>? effStacks;
    if (json['effectiveStacksPerStreet'] != null) {
      effStacks = <String, int>{};
      (json['effectiveStacksPerStreet'] as Map).forEach((key, value) {
        effStacks![key as String] = value as int;
      });
    }
    Map<String, String>? notes;
    if (json['validationNotes'] != null) {
      notes = <String, String>{};
      (json['validationNotes'] as Map).forEach((key, value) {
        notes![key as String] = value as String;
      });
    }
    List<int>? collapsed;
    if (json['collapsedHistoryStreets'] != null) {
      collapsed = [for (final i in (json['collapsedHistoryStreets'] as List)) i as int];
    }
    List<int>? firsts;
    if (json['firstActionTaken'] != null) {
      firsts = [for (final i in (json['firstActionTaken'] as List)) i as int];
    }
    List<int>? folded;
    if (json['foldedPlayers'] != null) {
      folded = [for (final i in (json['foldedPlayers'] as List)) i as int];
    }
    List<int>? allIn;
    if (json['allInPlayers'] != null) {
      allIn = [for (final i in (json['allInPlayers'] as List)) i as int];
    }
    Map<int, String?>? aTags;
    if (json['actionTags'] != null) {
      aTags = <int, String?>{};
      (json['actionTags'] as Map).forEach((key, value) {
        aTags![int.parse(key as String)] = value as String?;
      });
    }
    Map<int, String>? showDesc;
    if (json['showdownDescriptions'] != null) {
      showDesc = <int, String>{};
      (json['showdownDescriptions'] as Map).forEach((key, value) {
        showDesc![int.parse(key as String)] = value as String;
      });
    }
    Map<int, int>? elimPos;
    if (json['eliminatedPositions'] != null) {
      elimPos = <int, int>{};
      (json['eliminatedPositions'] as Map).forEach((key, value) {
        elimPos![int.parse(key as String)] = value as int;
      });
    }
    List<ActionEvaluationRequest>? pending;
    if (json['pendingEvaluations'] != null) {
      pending = [
        for (final e in (json['pendingEvaluations'] as List))
          ActionEvaluationRequest.fromJson(
              Map<String, dynamic>.from(e as Map))
      ];
    }
    final playbackIndex = json['playbackIndex'] as int? ?? 0;
    final showFullBoard = json['showFullBoard'] as bool? ?? false;
    final revealStreet = json['revealStreet'] as int? ?? boardStreet;
    final commentCursor = json['commentCursor'] as int?;
    final tagsCursor = json['tagsCursor'] as int?;
    Map<int, PlayerType> types = {};
    if (json['playerTypes'] != null) {
      (json['playerTypes'] as Map).forEach((key, value) {
        types[int.parse(key as String)] =
            PlayerType.values.firstWhere(
          (e) => e.name == value,
          orElse: () => PlayerType.unknown,
        );
      });
    } else {
      for (final k in positions.keys) {
        types[k] = PlayerType.unknown;
      }
    }
    return SavedHand(
      name: json['name'] as String? ?? '',
      heroIndex: json['heroIndex'] as int? ?? 0,
      heroPosition: json['heroPosition'] as String? ?? 'BTN',
      numberOfPlayers: json['numberOfPlayers'] as int? ?? 6,
      playerCards: pc,
      boardCards: board,
      boardStreet: boardStreet,
      revealedCards: rc,
      opponentIndex: oppIndex,
      activePlayerIndex: activeIndex,
      actions: acts,
      stackSizes: stack,
      currentBets: bets,
      remainingStacks: remaining,
      winnings: wins,
      totalPot: totalPot,
      rake: rake,
      tournamentId: tournamentId,
      buyIn: buyIn,
      totalPrizePool: totalPrizePool,
      numberOfEntrants: numberOfEntrants,
      gameType: gameType,
      category: category,
      playerPositions: positions,
      playerTypes: types,
      comment: json['comment'] as String?,
      tags: tags,
      rating: rating,
      commentCursor: commentCursor,
      tagsCursor: tagsCursor,
      isFavorite: isFavorite,
      savedAt: savedAt,
      date: date,
      expectedAction: json['expectedAction'] as String?,
      gtoAction: json['gtoAction'] as String?,
      rangeGroup: json['rangeGroup'] as String?,
      feedbackText: json['feedbackText'] as String?,
      evLoss: (json['evLoss'] as num?)?.toDouble(),
      effectiveStacksPerStreet: effStacks,
      validationNotes: notes,
      collapsedHistoryStreets: collapsed,
      firstActionTaken: firsts,
      foldedPlayers: folded,
      allInPlayers: allIn,
      actionTags: aTags,
      showdownDescriptions: showDesc,
      eliminatedPositions: elimPos,
      pendingEvaluations: pending,
      playbackIndex: playbackIndex,
      showFullBoard: showFullBoard,
      revealStreet: revealStreet,
      sessionId: sessionId,
    );
  }
}

