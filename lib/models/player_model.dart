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
  /// Known revealed cards for this player, if any.
  List<CardModel>? revealedCards;
  final Map<String, List<PlayerActionModel>> actions;
  PlayerType type;

  PlayerModel({required this.name, this.type = PlayerType.unknown, this.revealedCards})
      : cards = [],
        actions = {
          'Preflop': [],
          'Flop': [],
          'Turn': [],
          'River': [],
        };
}
