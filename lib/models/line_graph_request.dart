class LineGraphRequest {
  final String gameStage;
  final List<String> requiredTags;
  final int minActions;
  final int maxActions;

  const LineGraphRequest({
    required this.gameStage,
    this.requiredTags = const [],
    this.minActions = 0,
    this.maxActions = 999,
  }) : assert(minActions <= maxActions);
}
