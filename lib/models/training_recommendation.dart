enum TrainingRecommendationType { mistakeReplay, weaknessDrill, reinforce }

class TrainingRecommendation {
  final String title;
  final TrainingRecommendationType type;
  final String? goalTag;
  final double score;

  const TrainingRecommendation({
    required this.title,
    required this.type,
    this.goalTag,
    required this.score,
  });
}
