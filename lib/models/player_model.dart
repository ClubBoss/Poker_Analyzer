import 'action_model.dart';

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
  final Map<String, List<PlayerActionModel>> actions;
  PlayerType type;

  PlayerModel({required this.name, this.type = PlayerType.unknown})
      : cards = [],
        actions = {
          'Preflop': [],
          'Flop': [],
          'Turn': [],
          'River': [],
        };
}
