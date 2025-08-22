import '../models/pack_engagement_stats.dart';
import 'session_log_service.dart';
import 'suggested_training_packs_history_service.dart';

class PackSuggestionAnalyticsEngine {
  final SessionLogService logs;

  PackSuggestionAnalyticsEngine({required this.logs});

  Future<List<PackEngagementStats>> getStats({
    Duration since = const Duration(days: 30),
  }) async {
    await logs.load();
    final history =
        await SuggestedTrainingPacksHistoryService.getRecentSuggestions(
          limit: 100,
        );
    final cutoff = DateTime.now().subtract(since);

    final stats = <String, _MutableStat>{};

    for (final r in history) {
      if (r.timestamp.isBefore(cutoff)) continue;
      final s = stats.putIfAbsent(r.packId, () => _MutableStat());
      s.shown += 1;
    }

    for (final log in logs.logs) {
      if (log.startedAt.isBefore(cutoff)) break;
      final s = stats.putIfAbsent(log.templateId, () => _MutableStat());
      s.started += 1;
      s.completed += 1;
    }

    final list = [for (final e in stats.entries) e.value.toStats(e.key)]
      ..sort((a, b) => b.startedCount.compareTo(a.startedCount));
    return list;
  }
}

class _MutableStat {
  int shown = 0;
  int started = 0;
  int completed = 0;

  PackEngagementStats toStats(String id) => PackEngagementStats(
    packId: id,
    shownCount: shown,
    startedCount: started,
    completedCount: completed,
  );
}
