class LearningPathProgressSnapshot {
  final String pathId;
  final String stageId;
  final Map<String, double> subProgress;
  final int handsPlayed;
  final double accuracy;

  const LearningPathProgressSnapshot({
    required this.pathId,
    required this.stageId,
    Map<String, double>? subProgress,
    this.handsPlayed = 0,
    this.accuracy = 0.0,
  }) : subProgress = subProgress ?? const {};

  Map<String, dynamic> toJson() => {
        'pathId': pathId,
        'stageId': stageId,
        if (subProgress.isNotEmpty) 'subProgress': subProgress,
        'handsPlayed': handsPlayed,
        'accuracy': accuracy,
      };

  factory LearningPathProgressSnapshot.fromJson(Map<String, dynamic> json) {
    return LearningPathProgressSnapshot(
      pathId: json['pathId'] as String? ?? '',
      stageId: json['stageId'] as String? ?? '',
      subProgress: json['subProgress'] is Map
          ? (json['subProgress'] as Map).map(
              (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
            )
          : const <String, double>{},
      handsPlayed: (json['handsPlayed'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
