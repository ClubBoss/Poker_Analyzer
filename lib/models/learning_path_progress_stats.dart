class SectionStats {
  final String id;
  final String title;
  final int completedStages;
  final int totalStages;

  const SectionStats({
    required this.id,
    required this.title,
    required this.completedStages,
    required this.totalStages,
  });

  double get completionPercent =>
      totalStages == 0 ? 0.0 : completedStages / totalStages;
}

class LearningPathProgressStats {
  final int totalStages;
  final int completedStages;
  final double completionPercent;
  final List<SectionStats> sections;
  final List<String> lockedStageIds;

  const LearningPathProgressStats({
    required this.totalStages,
    required this.completedStages,
    required this.completionPercent,
    required this.sections,
    required this.lockedStageIds,
  });
}
