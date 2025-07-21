class TagSummary {
  final int total;
  final int correct;
  final double accuracy;
  final double? evBefore;
  final double? evAfter;

  const TagSummary({
    required this.total,
    required this.correct,
    required this.accuracy,
    this.evBefore,
    this.evAfter,
  });
}

class TrainingTrackSummary {
  final String goalId;
  final double accuracy;
  final int mistakeCount;
  final double? evBefore;
  final double? evAfter;
  final Map<String, TagSummary> tagBreakdown;

  const TrainingTrackSummary({
    required this.goalId,
    required this.accuracy,
    required this.mistakeCount,
    this.evBefore,
    this.evAfter,
    Map<String, TagSummary>? tagBreakdown,
  }) : tagBreakdown = tagBreakdown ?? const {};
}
