import 'card_model.dart';
import 'action_entry.dart';
import 'player_model.dart';
import 'action_evaluation_request.dart';
import 'package:json_annotation/json_annotation.dart';
import 'json_converters.dart';

part 'saved_hand.g.dart';

@JsonSerializable(explicitToJson: true)
class SavedHand {
  final String name;
  final String? spotId;
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
  final int anteBb;

  /// Custom category label for this hand.
  final String? category;
  @JsonKey(fromJson: _intIntMapFromJson, toJson: _intIntMapToJson)
  final Map<int, int> stackSizes;
  @JsonKey(
    fromJson: _intIntMapFromJsonNullable,
    toJson: _intIntMapToJsonNullable,
  )
  final Map<int, int>? currentBets;
  @JsonKey(
    fromJson: _intIntMapFromJsonNullable,
    toJson: _intIntMapToJsonNullable,
  )
  final Map<int, int>? remainingStacks;

  /// Winnings collected by each player in chips or big blinds.
  @JsonKey(
    fromJson: _intIntMapFromJsonNullable,
    toJson: _intIntMapToJsonNullable,
  )
  final Map<int, int>? winnings;

  /// Total pot size in chips or big blinds.
  final int? totalPot;

  /// Rake taken from the pot in chips or big blinds.
  final int? rake;
  @JsonKey(fromJson: _intStringMapFromJson, toJson: _intStringMapToJson)
  final Map<int, String> playerPositions;
  @JsonKey(fromJson: _playerTypeMapFromJson, toJson: _playerTypeMapToJson)
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
  final bool isDuplicate;
  bool isNew;
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
  final bool corrected;
  final double? evLossRecovered;
  final Map<String, int>? effectiveStacksPerStreet;
  final Map<String, String>? validationNotes;
  final List<int>? collapsedHistoryStreets;
  final List<int>? firstActionTaken;
  final List<int>? foldedPlayers;
  final List<int>? allInPlayers;
  @JsonKey(
    fromJson: _intNullableStringMapFromJson,
    toJson: _intNullableStringMapToJson,
  )
  final Map<int, String?>? actionTags;

  /// Descriptions shown at showdown for each player.
  @JsonKey(
    fromJson: _intStringMapFromJsonNullable,
    toJson: _intStringMapToJsonNullable,
  )
  final Map<int, String>? showdownDescriptions;

  /// Finishing positions for players eliminated from a tournament.
  @JsonKey(
    fromJson: _intIntMapFromJsonNullable,
    toJson: _intIntMapToJsonNullable,
  )
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
    this.spotId,
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
    this.anteBb = 0,
    this.category,
    required this.playerPositions,
    this.playerTypes,
    this.comment,
    List<String>? tags,
    this.rating = 0,
    this.commentCursor,
    this.tagsCursor,
    this.isFavorite = false,
    this.isDuplicate = false,
    this.isNew = false,
    this.sessionId = 0,
    DateTime? savedAt,
    DateTime? date,
    this.expectedAction,
    this.gtoAction,
    this.rangeGroup,
    this.feedbackText,
    this.evLoss,
    this.corrected = false,
    this.evLossRecovered,
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
    String? spotId,
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
    int? anteBb,
    String? category,
    Map<int, String>? playerPositions,
    Map<int, PlayerType>? playerTypes,
    String? comment,
    List<String>? tags,
    int? rating,
    int? commentCursor,
    int? tagsCursor,
    bool? isFavorite,
    bool? isDuplicate,
    bool? isNew,
    DateTime? savedAt,
    DateTime? date,
    String? expectedAction,
    String? gtoAction,
    String? rangeGroup,
    String? feedbackText,
    double? evLoss,
    bool? corrected,
    double? evLossRecovered,
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
      spotId: spotId ?? this.spotId,
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
          (this.currentBets == null
              ? null
              : Map<int, int>.from(this.currentBets!)),
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
      anteBb: anteBb ?? this.anteBb,
      category: category ?? this.category,
      playerPositions:
          playerPositions ?? Map<int, String>.from(this.playerPositions),
      playerTypes: playerTypes ?? this.playerTypes,
      comment: comment ?? this.comment,
      tags: tags ?? List<String>.from(this.tags),
      rating: rating ?? this.rating,
      commentCursor: commentCursor ?? this.commentCursor,
      tagsCursor: tagsCursor ?? this.tagsCursor,
      isFavorite: isFavorite ?? this.isFavorite,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      isNew: isNew ?? this.isNew,
      sessionId: sessionId ?? this.sessionId,
      savedAt: savedAt ?? this.savedAt,
      date: date ?? this.date,
      expectedAction: expectedAction ?? this.expectedAction,
      gtoAction: gtoAction ?? this.gtoAction,
      rangeGroup: rangeGroup ?? this.rangeGroup,
      feedbackText: feedbackText ?? this.feedbackText,
      evLoss: evLoss ?? this.evLoss,
      corrected: corrected ?? this.corrected,
      evLossRecovered: evLossRecovered ?? this.evLossRecovered,
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
      pendingEvaluations: pendingEvaluations ??
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
                    ),
                ]),
      playbackIndex: playbackIndex ?? this.playbackIndex,
      showFullBoard: showFullBoard ?? this.showFullBoard,
      revealStreet: revealStreet ?? this.revealStreet,
    );
  }

  factory SavedHand.fromJson(Map<String, dynamic> json) =>
      _$SavedHandFromJson(json);

  Map<String, dynamic> toJson() => _$SavedHandToJson(this);

  double? get heroEv {
    for (final a in actions) {
      if (a.street == 0 && a.playerIndex == heroIndex && a.ev != null) {
        return a.ev;
      }
    }
    return null;
  }

  double? get heroIcmEv {
    for (final a in actions) {
      if (a.street == 0 && a.playerIndex == heroIndex && a.icmEv != null) {
        return a.icmEv;
      }
    }
    return null;
  }

  SavedHand markAsCorrected() {
    return copyWith(corrected: true, evLossRecovered: evLoss ?? 0);
  }
}
