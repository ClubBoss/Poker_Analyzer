import '../../../models/game_type.dart';

class PackGenerationRequest {
  final GameType gameType;
  final int bb;
  final List<String> positions;
  final String title;
  final String description;
  final List<String> tags;
  final int count;
  final bool multiplePositions;
  const PackGenerationRequest({
    required this.gameType,
    required this.bb,
    required this.positions,
    this.title = '',
    this.description = '',
    List<String>? tags,
    this.count = 25,
    this.multiplePositions = false,
  }) : tags = tags ?? const [];
}
