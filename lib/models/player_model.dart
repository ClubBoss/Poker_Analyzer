import 'action_model.dart';
import 'card_model.dart';
import 'copy_with_mixin.dart';
import 'poker_street.dart';

/// Different types of players at the table.
enum PlayerType {
  /// Aggressive pro player
  shark,

  /// Weak player
  fish,

  /// Passive player who often calls
  callingStation,

  /// Extremely aggressive player
  maniac,

  /// Very tight player
  nit,

  /// Unknown player type
  unknown,
}

class PlayerModel with CopyWithMixin<PlayerModel> {
  final String name;
  final List<String> cards;

  /// Cards that this player has revealed. Two slots that may be null.
  final List<CardModel?> revealedCards;
  final Map<PokerStreet, List<PlayerActionModel>> actions;
  PlayerType type;
  int stack;
  int bet;

  PlayerModel({
    required this.name,
    this.type = PlayerType.unknown,
    this.stack = 0,
    this.bet = 0,
    List<CardModel?>? revealedCards,
  }) : cards = [],
       revealedCards =
           revealedCards ?? List<CardModel?>.filled(2, null, growable: false),
       actions = {
         PokerStreet.preflop: [],
         PokerStreet.flop: [],
         PokerStreet.turn: [],
         PokerStreet.river: [],
       };

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'cards': cards,
    'revealedCards': [
      for (final c in revealedCards)
        c != null ? {'rank': c.rank, 'suit': c.suit} : null,
    ],
    'actions': actions.map(
      (k, v) => MapEntry(pokerStreetToString(k), [
        for (final a in v)
          {'type': a.type.name, if (a.size != null) 'size': a.size},
      ]),
    ),
    'type': type.name,
    'stack': stack,
    'bet': bet,
  };

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    final model = PlayerModel(
      name: json['name'] as String? ?? '',
      type: PlayerType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PlayerType.unknown,
      ),
      stack: json['stack'] as int? ?? 0,
      bet: json['bet'] as int? ?? 0,
      revealedCards: [
        for (final item in (json['revealedCards'] as List? ?? [null, null]))
          item == null
              ? null
              : CardModel(
                  rank: item['rank'] as String,
                  suit: item['suit'] as String,
                ),
      ],
    );
    model.cards.addAll([
      for (final c in (json['cards'] as List? ?? [])) c as String,
    ]);
    final acts = json['actions'] as Map? ?? {};
    acts.forEach((key, value) {
      final street = pokerStreetFromString(key as String);
      model.actions[street] = [
        for (final a in (value as List? ?? []))
          PlayerActionModel(
            type: PlayerActionType.values.firstWhere(
              (e) => e.name == a['type'],
              orElse: () => PlayerActionType.check,
            ),
            size: (a['size'] as num?)?.toDouble(),
          ),
      ];
    });
    return model;
  }

  @override
  PlayerModel Function(Map<String, dynamic> json) get fromJson =>
      PlayerModel.fromJson;
}
