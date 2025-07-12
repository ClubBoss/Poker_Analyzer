class EvRecoveryGoal {
  final String type;
  final double target;
  final double progress;
  final bool completed;

  const EvRecoveryGoal({
    required this.type,
    required this.target,
    required this.progress,
    required this.completed,
  });
}
