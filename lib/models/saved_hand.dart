import 'card_model.dart';
import 'action_entry.dart';
import 'player_model.dart';

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
  final List<ActionEntry> actions;
  final Map<int, int> stackSizes;
  final Map<int, int>? remainingStacks;
  final Map<int, String> playerPositions;
  final Map<int, PlayerType>? playerTypes;
  final String? comment;
  final List<String> tags;
  final bool isFavorite;
  final DateTime date;
  final String? expectedAction;
  final String? feedbackText;

  SavedHand({
    required this.name,
    required this.heroIndex,
    required this.heroPosition,
    required this.numberOfPlayers,
    required this.playerCards,
    required this.boardCards,
    List<List<CardModel>>? revealedCards,
    this.opponentIndex,
    required this.actions,
    required this.stackSizes,
    this.remainingStacks,
    required this.playerPositions,
    this.playerTypes,
    this.comment,
    List<String>? tags,
    this.isFavorite = false,
    DateTime? date,
    this.expectedAction,
    this.feedbackText,
    revealedCards,
  })  : tags = tags ?? [],
        revealedCards = revealedCards ??
            List.generate(numberOfPlayers, (_) => <CardModel>[]),
        date = date ?? DateTime.now();

  SavedHand copyWith({
    String? name,
    int? heroIndex,
    String? heroPosition,
    int? numberOfPlayers,
    List<List<CardModel>>? playerCards,
    List<CardModel>? boardCards,
    List<List<CardModel>>? revealedCards,
    int? opponentIndex,
    List<ActionEntry>? actions,
    Map<int, int>? stackSizes,
    Map<int, int>? remainingStacks,
    Map<int, String>? playerPositions,
    Map<int, PlayerType>? playerTypes,
    String? comment,
    List<String>? tags,
    bool? isFavorite,
    DateTime? date,
    String? expectedAction,
    String? feedbackText,
  }) {
    return SavedHand(
      name: name ?? this.name,
      heroIndex: heroIndex ?? this.heroIndex,
      heroPosition: heroPosition ?? this.heroPosition,
      numberOfPlayers: numberOfPlayers ?? this.numberOfPlayers,
      playerCards: playerCards ??
          [for (final list in this.playerCards) List<CardModel>.from(list)],
      boardCards: boardCards ?? List<CardModel>.from(this.boardCards),
      revealedCards: revealedCards ??
          [for (final list in this.revealedCards) List<CardModel>.from(list)],
      opponentIndex: opponentIndex ?? this.opponentIndex,
      actions: actions ?? List<ActionEntry>.from(this.actions),
      stackSizes: stackSizes ?? Map<int, int>.from(this.stackSizes),
      remainingStacks: remainingStacks ??
          (this.remainingStacks == null
              ? null
              : Map<int, int>.from(this.remainingStacks!)),
      playerPositions: playerPositions ?? Map<int, String>.from(this.playerPositions),
      playerTypes: playerTypes ?? this.playerTypes,
      comment: comment ?? this.comment,
      tags: tags ?? List<String>.from(this.tags),
      isFavorite: isFavorite ?? this.isFavorite,
      date: date ?? this.date,
      expectedAction: expectedAction ?? this.expectedAction,
      feedbackText: feedbackText ?? this.feedbackText,
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
        if (opponentIndex != null) 'opponentIndex': opponentIndex,
        'actions': [
          for (final a in actions)
            {
              'street': a.street,
              'playerIndex': a.playerIndex,
              'action': a.action,
              'amount': a.amount,
              'generated': a.generated,
              'timestamp': a.timestamp.toIso8601String(),
            }
        ],
        'stackSizes': stackSizes.map((k, v) => MapEntry(k.toString(), v)),
        if (remainingStacks != null)
          'remainingStacks':
              remainingStacks!.map((k, v) => MapEntry(k.toString(), v)),
        'playerPositions': playerPositions.map((k, v) => MapEntry(k.toString(), v)),
        if (playerTypes != null)
          'playerTypes':
              playerTypes!.map((k, v) => MapEntry(k.toString(), v.name)),
        if (comment != null) 'comment': comment,
        'tags': tags,
        'isFavorite': isFavorite,
        'date': date.toIso8601String(),
        if (expectedAction != null) 'expectedAction': expectedAction,
        if (feedbackText != null) 'feedbackText': feedbackText,
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
    final oppIndex = json['opponentIndex'] as int?;
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
        )
    ];
    final stack = <int, int>{};
    (json['stackSizes'] as Map? ?? {}).forEach((key, value) {
      stack[int.parse(key as String)] = value as int;
    });
    Map<int, int>? remaining;
    if (json['remainingStacks'] != null) {
      remaining = <int, int>{};
      (json['remainingStacks'] as Map).forEach((key, value) {
        remaining![int.parse(key as String)] = value as int;
      });
    }
    final positions = <int, String>{};
    (json['playerPositions'] as Map? ?? {}).forEach((key, value) {
      positions[int.parse(key as String)] = value as String;
    });
    final tags = [for (final t in (json['tags'] as List? ?? [])) t as String];
    final isFavorite = json['isFavorite'] as bool? ?? false;
    final date = DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now();
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
      revealedCards: rc,
      opponentIndex: oppIndex,
      actions: acts,
      stackSizes: stack,
      remainingStacks: remaining,
      playerPositions: positions,
      playerTypes: types,
      comment: json['comment'] as String?,
      tags: tags,
      isFavorite: isFavorite,
      date: date,
      expectedAction: json['expectedAction'] as String?,
      feedbackText: json['feedbackText'] as String?,
    );
  }
}

