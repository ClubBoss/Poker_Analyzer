import 'tag_mastery_history_service.dart';

enum TagTrend { rising, flat, falling }

class TagMasteryTrendService {
  final TagMasteryHistoryService history;
  TagMasteryTrendService({TagMasteryHistoryService? history})
      : history = history ?? TagMasteryHistoryService();

  static Map<String, TagTrend>? _cache;
  static int _cacheDays = 0;
  static DateTime _cacheTime = DateTime.fromMillisecondsSinceEpoch(0);

  Future<Map<String, TagTrend>> computeTrends({int days = 14}) async {
    if (days <= 0) days = 14;
    final now = DateTime.now();
    if (_cache != null &&
        _cacheDays == days &&
        now.difference(_cacheTime) < const Duration(hours: 1)) {
      return _cache!;
    }

    final hist = await history.getHistory();
    final result = <String, TagTrend>{};
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: days - 1));

    for (final entry in hist.entries) {
      final data = List<double>.filled(days, 0);
      for (final e in entry.value) {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        if (d.isBefore(start) || d.isAfter(today)) continue;
        final idx = d.difference(start).inDays;
        if (idx >= 0 && idx < days) data[idx] += e.xp.toDouble();
      }
      // 3-day moving average
      final smoothed = List<double>.generate(days, (i) {
        double sum = 0;
        int count = 0;
        for (int j = i - 2; j <= i; j++) {
          if (j >= 0 && j < days) {
            sum += data[j];
            count++;
          }
        }
        return count > 0 ? sum / count : 0;
      });

      if (smoothed.length < 2) {
        result[entry.key] = TagTrend.flat;
        continue;
      }

      final n = smoothed.length;
      final xs = [for (var i = 0; i < n; i++) i + 1];
      final sumX = xs.reduce((a, b) => a + b);
      final sumX2 = xs.map((e) => e * e).reduce((a, b) => a + b);
      final sumY = smoothed.reduce((a, b) => a + b);
      final sumXY = [
        for (var i = 0; i < n; i++) xs[i] * smoothed[i],
      ].reduce((a, b) => a + b);
      final denom = n * sumX2 - sumX * sumX;
      double slope = 0;
      if (denom != 0) {
        slope = (n * sumXY - sumX * sumY) / denom;
      }
      const eps = 0.5;
      if (slope > eps) {
        result[entry.key] = TagTrend.rising;
      } else if (slope < -eps) {
        result[entry.key] = TagTrend.falling;
      } else {
        result[entry.key] = TagTrend.flat;
      }
    }

    _cache = result;
    _cacheTime = now;
    _cacheDays = days;
    return result;
  }
}
