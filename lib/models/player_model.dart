import 'action_model.dart';
import 'card_model.dart';

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

class PlayerModel {
  final String name;
  final List<String> cards;
  /// Cards that this player has revealed. Two slots that may be null.
  final List<CardModel?> revealedCards;
  final Map<String, List<PlayerActionModel>> actions;
  PlayerType type;

  PlayerModel({
    required this.name,
    this.type = PlayerType.unknown,
    List<CardModel?>? revealedCards,
  })  : cards = [],
        revealedCards =
            revealedCards ?? List<CardModel?>.filled(2, null, growable: false),
        actions = {
          'Preflop': [],
          'Flop': [],
          'Turn': [],
          'River': [],
        };

  PlayerModel copyWith({
    String? name,
    PlayerType? type,
    List<CardModel?>? revealedCards,
  }) {
    return PlayerModel(
      name: name ?? this.name,
      type: type ?? this.type,
      revealedCards: revealedCards ??
          List<CardModel?>.from(this.revealedCards),
    )
      ..cards.addAll(cards)
      ..actions.addAll({
        for (final entry in actions.entries)
          entry.key: List<PlayerActionModel>.from(entry.value)
      });
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'cards': cards,
        'revealedCards': [
          for (final c in revealedCards)
            c != null ? {'rank': c.rank, 'suit': c.suit} : null
        ],
        'actions': actions.map((k, v) => MapEntry(k, [
              for (final a in v)
                {
                  'type': a.type.name,
                  if (a.size != null) 'size': a.size,
                }
            ])),
        'type': type.name,
      };

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    final model = PlayerModel(
      name: json['name'] as String? ?? '',
      type: PlayerType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PlayerType.unknown,
      ),
      revealedCards: [
        for (final item in (json['revealedCards'] as List? ?? [null, null]))
          item == null
              ? null
              : CardModel(rank: item['rank'] as String, suit: item['suit'] as String)
      ],
    );
    model.cards.addAll([for (final c in (json['cards'] as List? ?? [])) c as String]);
    final acts = json['actions'] as Map? ?? {};
    acts.forEach((key, value) {
      model.actions[key as String] = [
        for (final a in (value as List? ?? []))
          PlayerActionModel(
            type: PlayerActionType.values.firstWhere(
              (e) => e.name == a['type'],
              orElse: () => PlayerActionType.check,
            ),
            size: (a['size'] as num?)?.toDouble(),
          )
      ];
    });
    return model;
  }
}
