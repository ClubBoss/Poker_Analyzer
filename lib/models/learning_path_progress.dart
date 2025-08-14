class LearningPathProgress {
  final int completedStages;
  final int totalStages;
  final double overallAccuracy;
  final String? currentStageId;

  const LearningPathProgress({
    required this.completedStages,
    required this.totalStages,
    required this.overallAccuracy,
    this.currentStageId,
  });

  /// Ratio of completed to total stages in the range 0.0-1.0.
  double get percentComplete =>
      totalStages == 0 ? 0.0 : completedStages / totalStages;

  bool get finished => totalStages > 0 && completedStages >= totalStages;
}
