import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/booster_stats.dart';
import '../models/player_profile.dart';
import '../models/v2/training_pack_template_v2.dart';

class BoosterSessionTracker {
  BoosterSessionTracker._();
  static final BoosterSessionTracker instance = BoosterSessionTracker._();

  static const String _countsKey = 'booster_tag_counts';
  static const String _lastKey = 'booster_last_date';
  static const String _streakKey = 'booster_streak';
  static const String _totalKey = 'booster_total';
  static const String _recentKey = 'booster_recent_tags';

  Future<Map<String, int>> _loadCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_countsKey);
    if (raw == null) return <String, int>{};
    try {
      final data = jsonDecode(raw);
      if (data is Map) {
        return {
          for (final e in data.entries)
            e.key.toString(): (e.value as num?)?.toInt() ?? 0
        };
      }
    } catch (_) {}
    return <String, int>{};
  }

  Future<void> _saveCounts(Map<String, int> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_countsKey, jsonEncode(map));
  }

  Future<BoosterStats> trackSession(
    TrainingPackTemplateV2 booster,
    PlayerProfile profile, {
    double confidenceDelta = 0.05,
    DateTime? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final counts = await _loadCounts();
    final date = now ?? DateTime.now();
    final tags = <String>{for (final t in booster.tags) t.trim().toLowerCase()}
      ..removeWhere((t) => t.isEmpty);

    for (final t in tags) {
      counts.update(t, (v) => v + 1, ifAbsent: () => 1);
      profile.boosterCompletions.update(t, (v) => v + 1, ifAbsent: () => 1);
      final acc = profile.tagAccuracy[t] ?? 0.5;
      profile.tagAccuracy[t] = (acc + confidenceDelta).clamp(0.0, 1.0);
    }
    await _saveCounts(counts);

    final total = (prefs.getInt(_totalKey) ?? 0) + 1;
    await prefs.setInt(_totalKey, total);

    final today = DateTime(date.year, date.month, date.day);
    final lastStr = prefs.getString(_lastKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    int streak = prefs.getInt(_streakKey) ?? 0;
    if (last != null) {
      final lastDay = DateTime(last.year, last.month, last.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 1) {
        streak += 1;
      } else if (diff > 1) {
        streak = 1;
      } else if (streak == 0) {
        streak = 1;
      }
    } else {
      streak = 1;
    }
    prefs
      ..setString(_lastKey, today.toIso8601String())
      ..setInt(_streakKey, streak);

    profile.lastBoosterDate = today;
    profile.boosterStreak = streak;

    final recent = prefs.getStringList(_recentKey) ?? <String>[];
    for (final t in tags) {
      recent.remove(t);
      recent.insert(0, t);
    }
    while (recent.length > 10) {
      recent.removeLast();
    }
    await prefs.setStringList(_recentKey, recent);
    profile.tags.addAll(tags);

    return BoosterStats(
      counts: counts,
      totalCompleted: total,
      streak: streak,
      lastCompleted: today,
    );
  }
}
