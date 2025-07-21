class LearningPathProgress {
  final int completedStages;
  final int totalStages;
  final double percentComplete;

  const LearningPathProgress({
    required this.completedStages,
    required this.totalStages,
    required this.percentComplete,
  });

  bool get finished => totalStages > 0 && completedStages >= totalStages;
}
