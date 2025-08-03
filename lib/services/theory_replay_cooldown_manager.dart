import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';


/// Manages cooldowns for theory replay suggestions by tag.
class TheoryReplayCooldownManager {
  static const String _prefsKey = 'theory_replay_cooldowns';

  /// Default cooldown duration between suggestions.
  static Duration defaultCooldown = const Duration(hours: 24);

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
              if (e.value is String && DateTime.tryParse(e.value as String) != null)
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
      jsonEncode({for (final e in map.entries) e.key: e.value.toIso8601String()}),
    );
  }

  /// Returns true if [tag] was suggested within [cooldown].
  static Future<bool> isUnderCooldown(
    String tag, {
    Duration? cooldown,
  }) async {
    final map = await _load();
    final last = map[tag];
    if (last == null) return false;
    final cd = cooldown ?? defaultCooldown;
    return DateTime.now().difference(last) < cd;
  }

  /// Marks [tag] as suggested and prunes stale entries.
  static Future<void> markSuggested(String tag) async {
    final map = await _load();
    map[tag] = DateTime.now();
    final cutoff = DateTime.now().subtract(const Duration(days: 60));
    map.removeWhere((_, ts) => ts.isBefore(cutoff));
    await _save();
  }
}
