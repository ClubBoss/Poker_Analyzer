import 'session_log_service.dart';
import 'tag_mastery_history_service.dart';

class SkillTagDecayTracker {
  final SessionLogService logs;
  final TagMasteryHistoryService history;
  const SkillTagDecayTracker({
    required this.logs,
    required this.history,
  });

  double _computeSlope(List<double> values) {
    if (values.length < 2) return 0;
    final n = values.length;
    final xs = [for (var i = 0; i < n; i++) i + 1];
    final sumX = xs.reduce((a, b) => a + b);
    final sumX2 = xs.map((e) => e * e).reduce((a, b) => a + b);
    final sumY = values.reduce((a, b) => a + b);
    final sumXY =
        [for (var i = 0; i < n; i++) xs[i] * values[i]].reduce((a, b) => a + b);
    final denom = n * sumX2 - sumX * sumX;
    if (denom == 0) return 0;
    return (n * sumXY - sumX * sumY) / denom;
  }

  Future<List<String>> getDecayingTags({
    int maxTags = 5,
    int recentSessions = 10,
    DateTime? now,
    double timeWeight = 0.5,
    double trendWeight = 0.5,
  }) async {
    await logs.load();
    final hist = await history.getHistory();
    final current = now ?? DateTime.now();

    final scores = <String, double>{};

    for (final entry in hist.entries) {
      final tag = entry.key;
      if (entry.value.isEmpty) continue;
      final lastDate = entry.value.last.date;
      final daysSince = current.difference(lastDate).inDays.toDouble();

      final tagLogs = [
        for (final l in logs.logs)
          if (l.tags.contains(tag)) l
      ];
      if (tagLogs.isEmpty) {
        // Score purely based on inactivity
        final score = daysSince * timeWeight;
        if (score > 0) scores[tag] = score;
        continue;
      }

      tagLogs.sort((a, b) => a.completedAt.compareTo(b.completedAt));
      final recent =
          tagLogs.reversed.take(recentSessions).toList().reversed.toList();
      final acc = <double>[];
      for (final l in recent) {
        final total = l.correctCount + l.mistakeCount;
        if (total > 0) {
          acc.add(l.correctCount / total);
        }
      }

      final slope = _computeSlope(acc);
      final normalizedDays = daysSince / 30.0;
      final trendScore = slope < 0 ? -slope : 0;
      final score = timeWeight * normalizedDays + trendWeight * trendScore;
      if (score > 0) scores[tag] = score;
    }

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in sorted.take(maxTags)) e.key];
  }
}
