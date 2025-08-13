class PackAccuracy {
  final String id;
  final String name;
  final double accuracy;
  const PackAccuracy(
      {required this.id, required this.name, required this.accuracy});
}

class TrainingStats {
  final int totalSpots;
  final double avgAccuracy;
  final int streakDays;
  final List<PackAccuracy> topPacks;
  final List<PackAccuracy> bottomPacks;
  const TrainingStats({
    required this.totalSpots,
    required this.avgAccuracy,
    required this.streakDays,
    this.topPacks = const [],
    this.bottomPacks = const [],
  });
}
