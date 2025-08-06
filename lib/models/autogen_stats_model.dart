class AutogenStatsModel {
  int totalPacks;
  int totalSpots;
  int skippedSpots;
  int fingerprintCount;

  AutogenStatsModel({
    this.totalPacks = 0,
    this.totalSpots = 0,
    this.skippedSpots = 0,
    this.fingerprintCount = 0,
  });

  AutogenStatsModel copyWith({
    int? totalPacks,
    int? totalSpots,
    int? skippedSpots,
    int? fingerprintCount,
  }) => AutogenStatsModel(
        totalPacks: totalPacks ?? this.totalPacks,
        totalSpots: totalSpots ?? this.totalSpots,
        skippedSpots: skippedSpots ?? this.skippedSpots,
        fingerprintCount: fingerprintCount ?? this.fingerprintCount,
      );
}
