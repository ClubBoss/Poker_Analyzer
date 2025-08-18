class SkillStat {
  final String category;
  final int handsPlayed;
  final double evAvg;
  final int mistakes;
  final DateTime lastUpdated;
  const SkillStat({
    required this.category,
    required this.handsPlayed,
    required this.evAvg,
    required this.mistakes,
    required this.lastUpdated,
  });
  Map<String, dynamic> toJson() => {
    'category': category,
    'hands': handsPlayed,
    'ev': evAvg,
    'mistakes': mistakes,
    'updated': lastUpdated.toIso8601String(),
  };
  factory SkillStat.fromJson(Map<String, dynamic> json) => SkillStat(
    category: json['category'] as String? ?? '',
    handsPlayed: json['hands'] as int? ?? 0,
    evAvg: (json['ev'] as num?)?.toDouble() ?? 0,
    mistakes: json['mistakes'] as int? ?? 0,
    lastUpdated:
        DateTime.tryParse(json['updated'] as String? ?? '') ?? DateTime.now(),
  );
}
