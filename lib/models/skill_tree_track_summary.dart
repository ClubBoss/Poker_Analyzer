class SkillTreeTrackSummary {
  final String title;
  final int completedCount;
  final double? avgEvLoss;
  final String motivationalLine;

  const SkillTreeTrackSummary({
    required this.title,
    required this.completedCount,
    this.avgEvLoss,
    required this.motivationalLine,
  });
}
