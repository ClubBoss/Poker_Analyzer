import '../models/recap_tag_performance.dart';
import 'session_log_service.dart';

class RecapTagAnalyticsService {
  final SessionLogService logs;

  RecapTagAnalyticsService({required this.logs});

  Future<Map<String, RecapTagPerformance>> computeRecapTagImprovements() async {
    await logs.load();
    final recapStats = <String, _MutableStat>{};
    final baselineStats = <String, _MutableStat>{};

    for (final log in logs.logs) {
      final tags = {for (final t in log.tags) t.trim().toLowerCase()};
      final isRecap = tags.contains('recap') || tags.contains('reinforcement');
      final total = log.correctCount + log.mistakeCount;
      if (total <= 0) continue;
      for (final t in tags) {
        if (t.isEmpty || t == 'recap' || t == 'reinforcement') continue;
        final map = isRecap ? recapStats : baselineStats;
        final stat = map.putIfAbsent(t, () => _MutableStat());
        stat.total += total;
        stat.correct += log.correctCount;
      }
    }

    final result = <String, RecapTagPerformance>{};
    recapStats.forEach((tag, stat) {
      final recapAcc = stat.accuracy;
      final baseAcc = baselineStats[tag]?.accuracy ?? 0;
      result[tag] = RecapTagPerformance(
        tag: tag,
        improvement: recapAcc - baseAcc,
      );
    });
    return result;
  }
}

class _MutableStat {
  int total = 0;
  int correct = 0;
  double get accuracy => total > 0 ? correct / total : 0;
}
