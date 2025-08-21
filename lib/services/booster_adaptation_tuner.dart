import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'booster_effectiveness_analyzer.dart';

/// Suggested adaptation to apply for boosters of a given tag.
enum BoosterAdaptation { increase, keep, reduce }

/// Tunes booster priorities based on historical effectiveness metrics.
class BoosterAdaptationTuner {
  final BoosterEffectivenessAnalyzer analyzer;

  BoosterAdaptationTuner({BoosterEffectivenessAnalyzer? analyzer})
      : analyzer = analyzer ?? BoosterEffectivenessAnalyzer();

  static final BoosterAdaptationTuner instance = BoosterAdaptationTuner();

  static const String _prefsKey = 'booster_adaptations';

  Map<String, BoosterAdaptation> _cache = {};
  bool _loaded = false;

  /// Clears cached data for tests.
  void resetForTest() {
    _loaded = false;
    _cache = {};
  }

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is Map) {
          _cache = {
            for (final e in data.entries)
              e.key.toString(): _parseAdaptation(e.value.toString()),
          };
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({for (final e in _cache.entries) e.key: e.value.name}),
    );
  }

  BoosterAdaptation _parseAdaptation(String value) {
    switch (value) {
      case 'increase':
        return BoosterAdaptation.increase;
      case 'reduce':
        return BoosterAdaptation.reduce;
      default:
        return BoosterAdaptation.keep;
    }
  }

  /// Returns the last computed adaptations from local storage.
  Future<Map<String, BoosterAdaptation>> loadAdaptations() async {
    await _load();
    return Map.unmodifiable(_cache);
  }

  /// Recomputes tag adaptations using booster effectiveness data.
  Future<Map<String, BoosterAdaptation>> computeAdaptations() async {
    final scores = await analyzer.computeEffectiveness();
    final result = <String, BoosterAdaptation>{};
    scores.forEach((tag, score) {
      if (score < 0.2) {
        result[tag] = BoosterAdaptation.reduce;
      } else if (score > 0.5) {
        result[tag] = BoosterAdaptation.increase;
      } else {
        result[tag] = BoosterAdaptation.keep;
      }
    });
    _cache = result;
    await _save();
    return result;
  }

  /// Saves [adaptation] for [tag] overriding any cached value.
  Future<void> saveAdaptation(String tag, BoosterAdaptation adaptation) async {
    final key = tag.trim().toLowerCase();
    if (key.isEmpty) return;
    await _load();
    _cache[key] = adaptation;
    await _save();
  }
}
