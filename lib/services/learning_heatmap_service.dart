import '../models/heatmap_entry.dart';
import '../models/track_play_history.dart';

class LearningHeatmapService {
  LearningHeatmapService();

  /// Builds a tag -> daily activity heatmap from [history].
  Map<String, List<HeatmapEntry>> buildHeatmap(List<TrackPlayHistory> history) {
    final map = <String, Map<DateTime, int>>{};

    for (final h in history) {
      final completedAt = h.completedAt;
      if (completedAt == null) continue;
      final tag = h.goalId.trim().toLowerCase();
      if (tag.isEmpty) continue;
      final day = DateTime(
        completedAt.year,
        completedAt.month,
        completedAt.day,
      );
      final tagMap = map.putIfAbsent(tag, () => <DateTime, int>{});
      tagMap.update(day, (v) => v + 1, ifAbsent: () => 1);
    }

    final result = <String, List<HeatmapEntry>>{};
    for (final entry in map.entries) {
      final list = [
        for (final e in entry.value.entries)
          HeatmapEntry(date: e.key, count: e.value),
      ]..sort((a, b) => a.date.compareTo(b.date));
      result[entry.key] = list;
    }
    return result;
  }
}
