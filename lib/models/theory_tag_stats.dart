class TheoryTagStats {
  final String tag;
  final int lessonCount;
  final int exampleCount;
  final double avgLength;
  final bool connectedToPath;

  const TheoryTagStats({
    required this.tag,
    required this.lessonCount,
    required this.exampleCount,
    required this.avgLength,
    required this.connectedToPath,
  });
}
