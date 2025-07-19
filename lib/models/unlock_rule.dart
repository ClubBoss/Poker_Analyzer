class UnlockRule {
  final String id;
  final String? unlockHint;
  final String? requiresPackCompleted;
  final double? requiresEV;
  final String? requiresGoal;
  final String? requiresStageCompleted;

  const UnlockRule({
    required this.id,
    this.unlockHint,
    this.requiresPackCompleted,
    this.requiresEV,
    this.requiresGoal,
    this.requiresStageCompleted,
  });
}
