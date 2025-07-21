enum TrainingRecommendationType { mistakeReplay, weaknessDrill, reinforce }

class TrainingRecommendation {
  final String title;
  final TrainingRecommendationType type;
  final String? goalTag;
  final double score;
  final String? packId;
  final String? reason;
  final double progress;
  final bool isUrgent;

  const TrainingRecommendation({
    required this.title,
    required this.type,
    this.goalTag,
    required this.score,
    this.packId,
    this.reason,
    this.progress = 0,
    this.isUrgent = false,
  });
}
