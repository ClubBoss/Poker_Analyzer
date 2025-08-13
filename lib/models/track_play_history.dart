import 'play_result.dart';

class TrackPlayHistory {
  final String goalId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final double? accuracy;
  final int? mistakeCount;
  final List<PlayResult> results;

  const TrackPlayHistory({
    required this.goalId,
    required this.startedAt,
    this.completedAt,
    this.accuracy,
    this.mistakeCount,
    List<PlayResult>? results,
  }) : results = results ?? const [];

  Map<String, dynamic> toJson() => {
        'goalId': goalId,
        'startedAt': startedAt.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        if (accuracy != null) 'accuracy': accuracy,
        if (mistakeCount != null) 'mistakeCount': mistakeCount,
        if (results.isNotEmpty)
          'results': [for (final r in results) r.toJson()],
      };

  factory TrackPlayHistory.fromJson(Map<String, dynamic> json) =>
      TrackPlayHistory(
        goalId: json['goalId'] as String? ?? '',
        startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ??
            DateTime.now(),
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'] as String)
            : null,
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        mistakeCount: (json['mistakeCount'] as num?)?.toInt(),
        results: [
          for (final r in (json['results'] as List? ?? []))
            PlayResult.fromJson(Map<String, dynamic>.from(r as Map))
        ],
      );
}
