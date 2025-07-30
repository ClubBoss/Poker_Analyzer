class RecapAnalyticsSummary {
  final Map<String, double> acceptanceRatesByTrigger;
  final List<String> mostDismissedLessonIds;
  final int ignoredStreakCount;

  const RecapAnalyticsSummary({
    this.acceptanceRatesByTrigger = const {},
    this.mostDismissedLessonIds = const [],
    this.ignoredStreakCount = 0,
  });
}
