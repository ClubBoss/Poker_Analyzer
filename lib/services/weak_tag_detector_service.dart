/// Detects the tags where the user performs the worst.
///
/// Utilizes [TrainingTagPerformanceEngine] to compute tag statistics and
/// caches results for an hour to minimize recomputation when the same
/// parameters are used.
import 'training_tag_performance_engine.dart';

class WeakTagDetectorService {
  static List<TagPerformance>? _cache;
  static DateTime _cacheTime = DateTime.fromMillisecondsSinceEpoch(0);
  static int _cacheAttempts = 0;
  static int _cacheLimit = 0;

  /// Compute and return the weakest tags sorted by accuracy.
  /// [minAttempts] sets the minimum attempt count per tag and [limit]
  /// limits the number of returned results.

  static Future<List<TagPerformance>> detectWeakTags(
      {int minAttempts = 10, int limit = 5}) async {
    final now = DateTime.now();
    if (_cache != null &&
        _cacheAttempts == minAttempts &&
        _cacheLimit == limit &&
        now.difference(_cacheTime) < const Duration(hours: 1)) {
      return _cache!;
    }

    final stats = await TrainingTagPerformanceEngine.computeTagStats();
    final list = stats.values
        .where((e) => e.totalAttempts >= minAttempts && e.accuracy < 0.85)
        .toList();

    list.sort((a, b) {
      final acc = a.accuracy.compareTo(b.accuracy);
      if (acc != 0) return acc;
      return b.totalAttempts.compareTo(a.totalAttempts);
    });

    final result = list.take(limit).toList();
    _cache = result;
    _cacheTime = now;
    _cacheAttempts = minAttempts;
    _cacheLimit = limit;
    return result;
  }
}
