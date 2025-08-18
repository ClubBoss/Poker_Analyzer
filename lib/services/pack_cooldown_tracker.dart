import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PackCooldownTracker {
  static const _prefsKey = 'pack_cooldown_timestamps';

  static Future<Map<String, DateTime>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is Map) {
          return {
            for (final e in data.entries)
              if (e.value is String &&
                  DateTime.tryParse(e.value as String) != null)
                e.key.toString(): DateTime.parse(e.value as String),
          };
        }
      } catch (_) {}
    }
    return {};
  }

  static Future<void> _save(Map<String, DateTime> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        for (final e in data.entries) e.key: e.value.toIso8601String(),
      }),
    );
  }

  static Future<bool> isRecentlySuggested(
    String packId, {
    Duration cooldown = const Duration(hours: 48),
  }) async {
    final map = await _load();
    final last = map[packId];
    if (last == null) return false;
    return DateTime.now().difference(last) < cooldown;
  }

  static Future<void> markAsSuggested(String packId) async {
    final map = await _load();
    map[packId] = DateTime.now();
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    map.removeWhere((_, ts) => ts.isBefore(cutoff));
    await _save(map);
  }
}
