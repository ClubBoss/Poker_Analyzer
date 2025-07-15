import '../../../models/game_type.dart';

class PackGenerationRequest {
  final GameType gameType;
  final int bb;
  final List<int>? bbList;
  final List<String> positions;
  final String title;
  final String description;
  final List<String> tags;
  final int count;
  final String? rangeGroup;
  final bool multiplePositions;
  const PackGenerationRequest({
    required this.gameType,
    this.bb = 0,
    this.bbList,
    required this.positions,
    this.title = '',
    this.description = '',
    List<String>? tags,
    this.count = 25,
    this.rangeGroup,
    this.multiplePositions = false,
  }) : tags = tags ?? const [];
}
