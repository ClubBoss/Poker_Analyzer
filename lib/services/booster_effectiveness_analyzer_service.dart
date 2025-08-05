import 'package:hive_flutter/hive_flutter.dart';

import 'booster_stats_tracker_service.dart';

/// Analyzes accuracy gains for booster sessions per tag.
class BoosterEffectivenessAnalyzerService {
  final BoosterStatsTrackerService tracker;

  BoosterEffectivenessAnalyzerService({BoosterStatsTrackerService? tracker})
      : tracker = tracker ?? BoosterStatsTrackerService();

  static const String _boxName = 'booster_stats_box';

  Future<Box<dynamic>> _openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.initFlutter();
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  /// Returns the average accuracy gain across booster sessions for [tag].
  ///
  /// Returns `null` if there are fewer than two sessions logged.
  Future<double?> getAverageGain(String tag) async {
    final progress = await tracker.getProgressForTag(tag);
    if (progress.length < 2) return null;
    double total = 0.0;
    for (var i = 1; i < progress.length; i++) {
      total += progress[i].accuracy - progress[i - 1].accuracy;
    }
    return total / (progress.length - 1);
  }

  /// Returns tags with highest average accuracy gains.
  ///
  /// Only tags with at least [minSessions] logged sessions are included.
  /// The returned map is ordered by descending effectiveness.
  Future<Map<String, double>> getTopEffectiveTags({int minSessions = 3}) async {
    final box = await _openBox();
    final tagProgress = <String, List<BoosterTagProgress>>{};

    for (var i = 0; i < box.length; i++) {
      final raw = box.getAt(i);
      if (raw is! Map) continue;
      final data = Map<String, dynamic>.from(raw as Map);
      final accMap = Map<String, dynamic>.from(data['accuracyPerTag'] ?? {});
      final ts = DateTime.fromMillisecondsSinceEpoch(
          (data['date'] as num?)?.toInt() ?? 0);
      accMap.forEach((tag, acc) {
        final t = tag.toString().trim().toLowerCase();
        final a = (acc as num?)?.toDouble();
        if (t.isEmpty || a == null) return;
        tagProgress
            .putIfAbsent(t, () => [])
            .add(BoosterTagProgress(date: ts, accuracy: a));
      });
    }

    final gains = <String, double>{};
    tagProgress.forEach((tag, list) {
      list.sort((a, b) => a.date.compareTo(b.date));
      if (list.length < minSessions) return;
      double total = 0.0;
      for (var i = 1; i < list.length; i++) {
        total += list[i].accuracy - list[i - 1].accuracy;
      }
      gains[tag] = total / (list.length - 1);
    });

    final sorted = gains.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in sorted) e.key: e.value};
  }
}
