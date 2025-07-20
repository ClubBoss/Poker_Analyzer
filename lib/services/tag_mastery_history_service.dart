import 'dart:convert';
import 'dart:collection';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/tag_xp_history_entry.dart';

class TagMasteryHistoryService {
  static const _tagXpPrefix = 'tag_xp_';

  /// Returns aggregated XP history per tag grouped by day.
  Future<Map<String, List<TagXpHistoryEntry>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, List<TagXpHistoryEntry>>{};

    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_tagXpPrefix)) continue;
      final tag = key.substring(_tagXpPrefix.length);
      final raw = prefs.getString(key);
      if (raw == null) continue;
      try {
        final data = jsonDecode(raw);
        if (data is Map<String, dynamic>) {
          final list = data['history'];
          final entries = <TagXpHistoryEntry>[];
          if (list is List) {
            for (final item in list) {
              if (item is Map) {
                entries.add(TagXpHistoryEntry.fromJson(
                    Map<String, dynamic>.from(item as Map)));
              }
            }
          }
          final map = <DateTime, TagXpHistoryEntry>{};
          for (final e in entries) {
            final date = DateTime(e.date.year, e.date.month, e.date.day);
            final existing = map[date];
            if (existing == null) {
              map[date] = TagXpHistoryEntry(
                date: date,
                xp: e.xp,
                source: e.source,
              );
            } else {
              map[date] = TagXpHistoryEntry(
                date: date,
                xp: existing.xp + e.xp,
                source: existing.source,
              );
            }
          }
          final sorted = map.values.toList()
            ..sort((a, b) => a.date.compareTo(b.date));
          result[tag] = sorted;
        }
      } catch (_) {}
    }

    return result;
  }

  /// Returns total XP per tag grouped by week starting on Monday.
  Future<Map<String, SplayTreeMap<DateTime, int>>> getWeeklyTotals() async {
    final hist = await getHistory();
    final result = <String, SplayTreeMap<DateTime, int>>{};
    for (final entry in hist.entries) {
      final byWeek = SplayTreeMap<DateTime, int>();
      for (final e in entry.value) {
        final monday = DateTime.utc(
            e.date.year, e.date.month, e.date.day - (e.date.weekday - 1));
        byWeek[monday] = (byWeek[monday] ?? 0) + e.xp;
      }
      result[entry.key] = byWeek;
    }
    return result;
  }

  /// Determines whether tags are active within [dormant] duration.
  Future<Map<String, bool>> getActiveFlags({
    Duration dormant = const Duration(days: 30),
  }) async {
    final hist = await getHistory();
    final now = DateTime.now();
    final result = <String, bool>{};
    for (final e in hist.entries) {
      if (e.value.isEmpty) {
        result[e.key] = false;
        continue;
      }
      final last = e.value.last.date;
      result[e.key] = now.difference(last) <= dormant;
    }
    return result;
  }
}
