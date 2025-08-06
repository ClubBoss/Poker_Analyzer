class SkillTagCoverageReport {
  final Map<String, int> tagCounts;
  final int totalSpots;
  final int minCount;
  final int maxCount;

  const SkillTagCoverageReport({
    required this.tagCounts,
    required this.totalSpots,
    this.minCount = 0,
    this.maxCount = 0,
  });

  double get minCoverage =>
      totalSpots == 0 ? 0 : minCount / totalSpots;
  double get maxCoverage =>
      totalSpots == 0 ? 0 : maxCount / totalSpots;
  double get imbalance => maxCount == 0
      ? 0
      : (maxCount - minCount) / maxCount;
}
