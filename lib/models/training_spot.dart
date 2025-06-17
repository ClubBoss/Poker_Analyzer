import 'action_entry.dart';
import 'card_model.dart';
import 'player_model.dart';
import 'saved_hand.dart';

class TrainingSpot {
  final List<List<CardModel>> playerCards;
  final List<CardModel> boardCards;
  final List<ActionEntry> actions;
  final int heroIndex;
  final int numberOfPlayers;
  final List<PlayerType> playerTypes;
  final List<String> positions;
  final List<int> stacks;
  final String? tournamentId;
  final int? buyIn;
  final int? totalPrizePool;
  final int? numberOfEntrants;
  final String? gameType;

  TrainingSpot({
    required this.playerCards,
    required this.boardCards,
    required this.actions,
    required this.heroIndex,
    required this.numberOfPlayers,
    required this.playerTypes,
    required this.positions,
    required this.stacks,
    this.tournamentId,
    this.buyIn,
    this.totalPrizePool,
    this.numberOfEntrants,
    this.gameType,
  });

  factory TrainingSpot.fromSavedHand(SavedHand hand) {
    return TrainingSpot(
      playerCards: [
        for (final list in hand.playerCards) List<CardModel>.from(list)
      ],
      boardCards: List<CardModel>.from(hand.boardCards),
      actions: List<ActionEntry>.from(hand.actions),
      heroIndex: hand.heroIndex,
      numberOfPlayers: hand.numberOfPlayers,
      playerTypes: [
        for (int i = 0; i < hand.numberOfPlayers; i++)
          hand.playerTypes?[i] ?? PlayerType.unknown
      ],
      positions: [
        for (int i = 0; i < hand.numberOfPlayers; i++)
          hand.playerPositions[i] ?? ''
      ],
      stacks: [
        for (int i = 0; i < hand.numberOfPlayers; i++)
          hand.stackSizes[i] ?? 0
      ],
      tournamentId: hand.tournamentId,
      buyIn: hand.buyIn,
      totalPrizePool: hand.totalPrizePool,
      numberOfEntrants: hand.numberOfEntrants,
      gameType: hand.gameType,
    );
  }

  Map<String, dynamic> toJson() => {
        'playerCards': [
          for (final list in playerCards)
            [for (final c in list) {'rank': c.rank, 'suit': c.suit}]
        ],
        'boardCards': [
          for (final c in boardCards) {'rank': c.rank, 'suit': c.suit}
        ],
        'actions': [
          for (final a in actions)
            {
              'street': a.street,
              'playerIndex': a.playerIndex,
              'action': a.action,
              if (a.amount != null) 'amount': a.amount,
            }
        ],
        'heroIndex': heroIndex,
        'numberOfPlayers': numberOfPlayers,
        'playerTypes': [for (final t in playerTypes) t.name],
        'positions': positions,
        'stacks': stacks,
        if (tournamentId != null) 'tournamentId': tournamentId,
        if (buyIn != null) 'buyIn': buyIn,
        if (totalPrizePool != null) 'totalPrizePool': totalPrizePool,
        if (numberOfEntrants != null) 'numberOfEntrants': numberOfEntrants,
        if (gameType != null) 'gameType': gameType,
      };

  factory TrainingSpot.fromJson(Map<String, dynamic> json) {
    final pcData = json['playerCards'] as List? ?? [];
    final pc = <List<CardModel>>[];
    for (final list in pcData) {
      if (list is List) {
        pc.add([
          for (final c in list)
            CardModel(rank: c['rank'] as String, suit: c['suit'] as String)
        ]);
      } else {
        pc.add([]);
      }
    }

    final board = <CardModel>[];
    for (final c in (json['boardCards'] as List? ?? [])) {
      if (c is Map) {
        board.add(CardModel(rank: c['rank'] as String, suit: c['suit'] as String));
      }
    }

    final acts = <ActionEntry>[];
    for (final a in (json['actions'] as List? ?? [])) {
      if (a is Map) {
        acts.add(ActionEntry(
          a['street'] as int,
          a['playerIndex'] as int,
          a['action'] as String,
          amount: (a['amount'] as num?)?.toInt(),
        ));
      }
    }

    final heroIndex = json['heroIndex'] as int? ?? 0;
    final numberOfPlayers = json['numberOfPlayers'] as int? ?? pc.length;

    final types = <PlayerType>[];
    final typesData = (json['playerTypes'] as List?)?.cast<String>() ?? [];
    for (int i = 0; i < numberOfPlayers; i++) {
      if (i < typesData.length) {
        types.add(PlayerType.values.firstWhere(
          (e) => e.name == typesData[i],
          orElse: () => PlayerType.unknown,
        ));
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

    return TrainingSpot(
      playerCards: pc,
      boardCards: board,
      actions: acts,
      heroIndex: heroIndex,
      numberOfPlayers: numberOfPlayers,
      playerTypes: types,
      positions: positions,
      stacks: stacks,
      tournamentId: json['tournamentId'] as String?,
      buyIn: (json['buyIn'] as num?)?.toInt(),
      totalPrizePool: (json['totalPrizePool'] as num?)?.toInt(),
      numberOfEntrants: (json['numberOfEntrants'] as num?)?.toInt(),
      gameType: json['gameType'] as String?,
    );
  }
}
