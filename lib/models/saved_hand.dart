import 'card_model.dart';
import 'action_entry.dart';

class SavedHand {
  final String name;
  final int heroIndex;
  final String heroPosition;
  final int numberOfPlayers;
  final List<List<CardModel>> playerCards;
  final List<CardModel> boardCards;
  final List<ActionEntry> actions;
  final Map<int, int> stackSizes;
  final Map<int, String> playerPositions;
  final Map<int, String>? playerTypes;
  final String? comment;

  SavedHand({
    required this.name,
    required this.heroIndex,
    required this.heroPosition,
    required this.numberOfPlayers,
    required this.playerCards,
    required this.boardCards,
    required this.actions,
    required this.stackSizes,
    required this.playerPositions,
    this.playerTypes,
    this.comment,
  });

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
        'actions': [
          for (final a in actions)
            {
              'street': a.street,
              'playerIndex': a.playerIndex,
              'action': a.action,
              'amount': a.amount,
              'generated': a.generated,
            }
        ],
        'stackSizes': stackSizes.map((k, v) => MapEntry(k.toString(), v)),
        'playerPositions': playerPositions.map((k, v) => MapEntry(k.toString(), v)),
        if (playerTypes != null)
          'playerTypes': playerTypes!.map((k, v) => MapEntry(k.toString(), v)),
        if (comment != null) 'comment': comment,
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
    final acts = [
      for (final a in (json['actions'] as List? ?? []))
        ActionEntry(a['street'] as int, a['playerIndex'] as int, a['action'] as String,
            amount: a['amount'] as int?, generated: a['generated'] as bool? ?? false)
    ];
    final stack = <int, int>{};
    (json['stackSizes'] as Map? ?? {}).forEach((key, value) {
      stack[int.parse(key as String)] = value as int;
    });
    final positions = <int, String>{};
    (json['playerPositions'] as Map? ?? {}).forEach((key, value) {
      positions[int.parse(key as String)] = value as String;
    });
    Map<int, String> types = {};
    if (json['playerTypes'] != null) {
      (json['playerTypes'] as Map).forEach((key, value) {
        types[int.parse(key as String)] = value as String;
      });
    } else {
      for (final k in positions.keys) {
        types[k] = 'standard';
      }
    }
    return SavedHand(
      name: json['name'] as String? ?? '',
      heroIndex: json['heroIndex'] as int? ?? 0,
      heroPosition: json['heroPosition'] as String? ?? 'BTN',
      numberOfPlayers: json['numberOfPlayers'] as int? ?? 6,
      playerCards: pc,
      boardCards: board,
      actions: acts,
      stackSizes: stack,
      playerPositions: positions,
      playerTypes: types,
      comment: json['comment'] as String?,
    );
  }
}

