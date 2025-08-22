import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'training_history_service_v2.dart';
import 'training_pack_stats_service.dart';
import 'training_tag_performance_engine.dart';

class TrainingGapDetectorService {
  TrainingGapDetectorService();

  static const _skillKey = 'stats_skill_stats';

  static List<TagPerformance>? _dormantCache;
  static DateTime _dormantCacheTime = DateTime.fromMillisecondsSinceEpoch(0);
  static Duration _dormantCacheGap = const Duration(days: 14);
  static int _dormantCacheLimit = 0;

  Future<List<String>> detectNeglectedTags({
    Duration maxAge = const Duration(days: 7),
  }) async {
    final history = await TrainingHistoryServiceV2.getHistory(limit: 200);
    final map = <String, DateTime>{};
    for (final e in history) {
      for (final t in e.tags) {
        final key = t.trim().toLowerCase();
        if (key.isEmpty) continue;
        final last = map[key];
        if (last == null || e.timestamp.isAfter(last)) {
          map[key] = e.timestamp;
        }
      }
    }
    final cutoff = DateTime.now().subtract(maxAge);
    final list = <String>[];
    map.forEach((tag, ts) {
      if (ts.isBefore(cutoff)) list.add(tag);
    });
    return list;
  }

  Future<Set<String>> detectNeglectedCategories({
    Duration maxAge = const Duration(days: 7),
  }) async {
    final tags = await detectNeglectedTags(maxAge: maxAge);
    return {
      for (final t in tags)
        if (t.startsWith('cat:')) t,
    };
  }

  Future<String?> detectWeakCategory({
    int minHands = 10,
    double evThreshold = 50,
  }) async {
    await TrainingPackStatsService.getCategoryStats();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_skillKey);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is Map) {
        String? result;
        double worst = double.infinity;
        for (final e in data.entries) {
          final v = e.value;
          if (v is Map) {
            final hands = (v['hands'] as num?)?.toInt() ?? 0;
            if (hands < minHands) continue;
            final mistakes = (v['mistakes'] as num?)?.toInt() ?? 0;
            if (hands == 0) continue;
            final acc = (hands - mistakes) * 100 / hands;
            if (acc < evThreshold && acc < worst) {
              worst = acc;
              result = e.key as String;
            }
          }
        }
        return result;
      }
    } catch (_) {}
    return null;
  }

  /// Detects tags that haven't been trained for [gap] duration.
  /// Results are cached for one hour using the same parameters.
  static Future<List<TagPerformance>> detectDormantTags({
    Duration gap = const Duration(days: 14),
    int limit = 5,
  }) async {
    final now = DateTime.now();
    if (_dormantCache != null &&
        _dormantCacheGap == gap &&
        _dormantCacheLimit == limit &&
        now.difference(_dormantCacheTime) < const Duration(hours: 1)) {
      return _dormantCache!;
    }

    final stats = await TrainingTagPerformanceEngine.computeTagStats();
    final list = stats.values
        .where(
          (e) =>
              e.totalAttempts >= 5 &&
              e.lastTrained != null &&
              now.difference(e.lastTrained!) >= gap,
        )
        .toList();

    list.sort((a, b) {
      final diff = a.lastTrained!.compareTo(b.lastTrained!);
      if (diff != 0) return diff;
      return a.accuracy.compareTo(b.accuracy);
    });

    final result = list.take(limit).toList();
    _dormantCache = result;
    _dormantCacheTime = now;
    _dormantCacheGap = gap;
    _dormantCacheLimit = limit;
    return result;
  }
}
