class BoosterStats {
  final Map<String, int> counts;
  final int totalCompleted;
  final int streak;
  final DateTime? lastCompleted;

  const BoosterStats({
    required this.counts,
    required this.totalCompleted,
    required this.streak,
    required this.lastCompleted,
  });
}
