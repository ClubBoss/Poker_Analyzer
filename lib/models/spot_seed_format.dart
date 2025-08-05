import 'card_model.dart';

class SpotSeedFormat {
  final String player;
  final List<String> handGroup;
  final String position;
  final String? opponentPosition;
  final double? heroStack;
  final List<CardModel> board;
  final List<String> villainActions;
  final List<String> tags;

  SpotSeedFormat({
    required this.player,
    required this.handGroup,
    required this.position,
    this.opponentPosition,
    this.heroStack,
    List<CardModel>? board,
    List<String>? villainActions,
    List<String>? tags,
  })  : board = board ?? [],
        villainActions = villainActions ?? [],
        tags = tags ?? [];

  SpotSeedFormat copyWith({
    List<CardModel>? board,
    List<String>? villainActions,
    List<String>? tags,
    double? heroStack,
    String? opponentPosition,
  }) => SpotSeedFormat(
        player: player,
        handGroup: handGroup,
        position: position,
        opponentPosition: opponentPosition ?? this.opponentPosition,
        heroStack: heroStack ?? this.heroStack,
        board: board ?? this.board,
        villainActions: villainActions ?? this.villainActions,
        tags: tags ?? this.tags,
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
