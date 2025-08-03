import 'card_model.dart';

class SpotSeedFormat {
  final String player;
  final List<String> handGroup;
  final String position;
  final List<CardModel> board;
  final List<String> villainActions;

  SpotSeedFormat({
    required this.player,
    required this.handGroup,
    required this.position,
    List<CardModel>? board,
    List<String>? villainActions,
  })  : board = board ?? [],
        villainActions = villainActions ?? [];

  SpotSeedFormat copyWith({
    List<CardModel>? board,
    List<String>? villainActions,
  }) => SpotSeedFormat(
        player: player,
        handGroup: handGroup,
        position: position,
        board: board ?? this.board,
        villainActions: villainActions ?? this.villainActions,
      );

  /// Returns the street name based on current board length.
  String get currentStreet {
    switch (board.length) {
      case 0:
        return 'preflop';
      case 3:
        return 'flop';
      case 4:
        return 'turn';
      case 5:
        return 'river';
      default:
        return 'unknown';
    }
  }
}
