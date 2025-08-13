import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'skill_tree_progress_analytics_service.dart';

/// Provides motivational messages based on skill tree progress.
class SkillTreeMotivationalHintEngine {
  /// Creates an engine with optional [cooldown].
  SkillTreeMotivationalHintEngine({Duration? cooldown})
      : cooldown = cooldown ?? defaultCooldown;

  /// Singleton instance with default cooldown.
  static final SkillTreeMotivationalHintEngine instance =
      SkillTreeMotivationalHintEngine();

  /// Default cooldown between messages.
  static Duration defaultCooldown = const Duration(hours: 6);

  final Duration cooldown;

  static const String _lastKey = 'skill_tree_hint_last';
  static const String _levelsKey = 'skill_tree_hint_levels';

  DateTime _lastShown = DateTime.fromMillisecondsSinceEpoch(0);
  Set<int> _shownLevels = {};
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final lastStr = prefs.getString(_lastKey);
    if (lastStr != null) {
      _lastShown = DateTime.tryParse(lastStr) ?? _lastShown;
    }
    final list = prefs.getStringList(_levelsKey);
    if (list != null) {
      _shownLevels = {
        for (final s in list)
          if (int.tryParse(s) != null) int.parse(s)
      };
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastKey, _lastShown.toIso8601String());
    await prefs.setStringList(
      _levelsKey,
      _shownLevels.map((e) => e.toString()).toList(),
    );
  }

  /// Clears stored state for testing purposes.
  @visibleForTesting
  Future<void> resetForTest() async {
    _loaded = false;
    _lastShown = DateTime.fromMillisecondsSinceEpoch(0);
    _shownLevels.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastKey);
    await prefs.remove(_levelsKey);
  }

  /// Returns a motivational message if a milestone is achieved.
  Future<String?> getMotivationalMessage(SkillTreeProgressStats stats) async {
    await _load();
    final now = DateTime.now();
    if (now.difference(_lastShown) < cooldown) return null;

    final levels = stats.completionRateByLevel.keys.toList()..sort();
    for (final level in levels) {
      final rate = stats.completionRateByLevel[level] ?? 0.0;
      if (rate == 1.0 && !_shownLevels.contains(level)) {
        _shownLevels.add(level);
        _lastShown = now;
        await _save();
        return 'Level $level complete!';
      }
    }

    if (stats.completionRate > 0.75) {
      _lastShown = now;
      await _save();
      return 'Almost there!';
    }

    return null;
  }
}
