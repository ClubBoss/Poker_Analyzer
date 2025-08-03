class LinePattern {
  final Map<String, List<String>> streets;
  final String? startingPosition;
  final String? boardTexture;
  final String? potType;

  LinePattern({
    required this.streets,
    this.startingPosition,
    this.boardTexture,
    this.potType,
  });
}
