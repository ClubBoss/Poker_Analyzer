import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';

import 'theory_recap_analytics_reporter.dart';
import 'smart_booster_dropoff_detector.dart';

/// Manages cooldowns for booster-triggered theory recaps.
class TheoryBoosterRecapDelayManager {
  static const String _prefsKey = 'theory_booster_recap_delay';
  static SmartBoosterDropoffDetector dropoff =
      SmartBoosterDropoffDetector.instance;

  static Map<String, DateTime>? _cache;

  static Future<Map<String, DateTime>> _load() async {
    if (_cache != null) return _cache!;
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is Map) {
          _cache = {
            for (final e in data.entries)
              if (e.value is String &&
                  DateTime.tryParse(e.value as String) != null)
                e.key.toString(): DateTime.parse(e.value as String),
          };
          return _cache!;
        }
      } catch (_) {}
    }
    _cache = <String, DateTime>{};
    return _cache!;
  }

  static Future<void> _save() async {
    final prefs = await PreferencesService.getInstance();
    final map = _cache ?? <String, DateTime>{};
    await prefs.setString(
      _prefsKey,
      jsonEncode(
          {for (final e in map.entries) e.key: e.value.toIso8601String()}),
    );
  }

  /// Returns true if [key] is still under [cooldown].
  static Future<bool> isUnderCooldown(String key, Duration cooldown) async {
    if (await dropoff.isInDropoffState()) {
      return true;
    }
    final map = await _load();
    final ts = map[key];
    if (ts == null) return false;
    final under = DateTime.now().difference(ts) < cooldown;
    if (under) {
      await TheoryRecapAnalyticsReporter.instance.logEvent(
        lessonId: key.startsWith('lesson:') ? key.substring(7) : '',
        trigger: key,
        outcome: 'cooldown',
        delay: DateTime.now().difference(ts),
      );
    }
    return under;
  }

  /// Marks [key] as prompted and prunes stale entries.
  static Future<void> markPrompted(String key) async {
    final map = await _load();
    map[key] = DateTime.now();
    final cutoff = DateTime.now().subtract(const Duration(days: 60));
    map.removeWhere((_, ts) => ts.isBefore(cutoff));
    await _save();
  }

  /// Returns the last time [key] was prompted if any.
  static Future<DateTime?> lastPromptTime(String key) async {
    final map = await _load();
    return map[key];
  }
}
