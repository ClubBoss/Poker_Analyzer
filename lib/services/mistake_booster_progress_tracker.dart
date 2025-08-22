import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Aggregated progress info for a mistake tag recovered via boosters.
class MistakeTagRecoveryStatus {
  final String tag;
  final int repetitions;
  final double totalDelta;

  MistakeTagRecoveryStatus({
    required this.tag,
    required this.repetitions,
    required this.totalDelta,
  });
}

/// Aggregated summary of overall booster recovery progress.
class MistakeRecoverySummary {
  final int reinforced;
  final int recovered;

  MistakeRecoverySummary({required this.reinforced, required this.recovered});
}

/// Tracks booster repetition progress for mistake-related tags.
class MistakeBoosterProgressTracker {
  MistakeBoosterProgressTracker._();
  static final MistakeBoosterProgressTracker instance =
      MistakeBoosterProgressTracker._();

  static const String _countPrefix = 'mistake_booster_count_';
  static const String _deltaPrefix = 'mistake_booster_delta_';

  /// Records mastery deltas for a completed booster session.
  Future<void> recordProgress(Map<String, double> tagDeltas) async {
    if (tagDeltas.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    for (final entry in tagDeltas.entries) {
      final tag = entry.key.toLowerCase();
      final countKey = '$_countPrefix$tag';
      final deltaKey = '$_deltaPrefix$tag';
      await prefs.setInt(countKey, (prefs.getInt(countKey) ?? 0) + 1);
      if (entry.value > 0) {
        final updated = (prefs.getDouble(deltaKey) ?? 0.0) + entry.value;
        await prefs.setDouble(deltaKey, updated);
      }
    }
  }

  /// Returns tags that reached [repeatThreshold] repetitions and
  /// accumulated [deltaThreshold] mastery improvement.
  Future<List<MistakeTagRecoveryStatus>> getCompletedTags({
    int repeatThreshold = 3,
    double deltaThreshold = 0.1,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final result = <MistakeTagRecoveryStatus>[];
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_countPrefix)) continue;
      final tag = key.substring(_countPrefix.length);
      final count = prefs.getInt(key) ?? 0;
      final delta = prefs.getDouble('$_deltaPrefix$tag') ?? 0.0;
      if (count >= repeatThreshold && delta >= deltaThreshold) {
        result.add(
          MistakeTagRecoveryStatus(
            tag: tag,
            repetitions: count,
            totalDelta: delta,
          ),
        );
      }
    }
    return result;
  }

  /// Returns counts of reinforced and fully recovered tags.
  Future<MistakeRecoverySummary> getRecoveryStatus({
    int repeatThreshold = 3,
    double deltaThreshold = 0.1,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    int reinforced = 0;
    int recovered = 0;
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_countPrefix)) continue;
      final tag = key.substring(_countPrefix.length);
      final count = prefs.getInt(key) ?? 0;
      final delta = prefs.getDouble('$_deltaPrefix$tag') ?? 0.0;
      if (count > 0) {
        reinforced++;
        if (count >= repeatThreshold && delta >= deltaThreshold) {
          recovered++;
        }
      }
    }
    return MistakeRecoverySummary(reinforced: reinforced, recovered: recovered);
  }

  /// Clears all stored progress (used by tests).
  Future<void> resetForTest() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith(_countPrefix) || k.startsWith(_deltaPrefix))
        .toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
