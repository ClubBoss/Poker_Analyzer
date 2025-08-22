class TrackMeta {
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int timesCompleted;

  TrackMeta({this.startedAt, this.completedAt, this.timesCompleted = 0});

  factory TrackMeta.fromJson(Map<String, dynamic> j) => TrackMeta(
    startedAt: j['startedAt'] != null
        ? DateTime.tryParse(j['startedAt'] as String)
        : null,
    completedAt: j['completedAt'] != null
        ? DateTime.tryParse(j['completedAt'] as String)
        : null,
    timesCompleted: (j['timesCompleted'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
    if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
    'timesCompleted': timesCompleted,
  };
}
