class GoalProgress {
  final String tag;
  final int stagesCompleted;
  final int totalStages;
  final double averageAccuracy;

  const GoalProgress({
    required this.tag,
    required this.stagesCompleted,
    this.totalStages = 3,
    required this.averageAccuracy,
  });
}
