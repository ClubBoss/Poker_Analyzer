enum GoalRecommendationType { decay, mistake }

class GoalRecommendation {
  final String tag;
  final String reason;
  final GoalRecommendationType type;

  const GoalRecommendation({
    required this.tag,
    required this.reason,
    required this.type,
  });
}
