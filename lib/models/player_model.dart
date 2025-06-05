import 'action_model.dart';

class PlayerModel {
  final String name;
  final List<String> cards;
  final Map<String, List<PlayerActionModel>> actions;

  PlayerModel({required this.name})
      : cards = [],
        actions = {
          'Preflop': [],
          'Flop': [],
          'Turn': [],
          'River': [],
        };
}