import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';

import 'user_action_logger.dart';

/// Central manager for suggestion cooldowns across the app.
class SuggestionCooldownManager {
  static const _prefsKey = 'suggestion_cooldowns';
  static bool debugLogging = false;

  static Future<Map<String, DateTime>> _load() async {
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return <String, DateTime>{};
    try {
      final data = jsonDecode(raw);
      if (data is Map) {
        return {
          for (final e in data.entries)
            if (e.value is String && DateTime.tryParse(e.value as String) != null)
              e.key.toString(): DateTime.parse(e.value as String)
        };
      }
    } catch (_) {}
    return <String, DateTime>{};
  }

  static Future<void> _save(Map<String, DateTime> data) async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({for (final e in data.entries) e.key: e.value.toIso8601String()}),
    );
  }

  /// Returns true if [packId] has been suggested within [cooldown].
  static Future<bool> isUnderCooldown(
    String packId, {
    Duration cooldown = const Duration(days: 14),
  }) async {
    final map = await _load();
    final last = map[packId];
    if (last == null) return false;
    final result = DateTime.now().difference(last) < cooldown;
    if (result && debugLogging) {
      await UserActionLogger.instance.log('cooldown.prevented.$packId');
    }
    return result;
  }

  /// Marks [packId] as suggested and prunes stale entries.
  static Future<void> markSuggested(String packId) async {
    final map = await _load();
    map[packId] = DateTime.now();
    _cleanup(map);
    await _save(map);
  }

  /// Removes entries older than [maxAge].
  static void _cleanup(Map<String, DateTime> map, {Duration maxAge = const Duration(days: 60)}) {
    final cutoff = DateTime.now().subtract(maxAge);
    map.removeWhere((_, ts) => ts.isBefore(cutoff));
  }
}
