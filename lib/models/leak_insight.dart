class LeakInsight {
  final String tag;
  final String position;
  final int stack;
  final String suggestedPackId;
  final double leakScore;

  const LeakInsight({
    required this.tag,
    required this.position,
    required this.stack,
    required this.suggestedPackId,
    required this.leakScore,
  });

  Map<String, dynamic> toJson() => {
        'tag': tag,
        'position': position,
        'stack': stack,
        'suggestedPackId': suggestedPackId,
        'leakScore': leakScore,
      };

  factory LeakInsight.fromJson(Map<String, dynamic> j) => LeakInsight(
        tag: j['tag']?.toString() ?? '',
        position: j['position']?.toString() ?? '',
        stack: (j['stack'] as num?)?.toInt() ?? 0,
        suggestedPackId: j['suggestedPackId']?.toString() ?? '',
        leakScore: (j['leakScore'] as num?)?.toDouble() ?? 0,
      );
}
