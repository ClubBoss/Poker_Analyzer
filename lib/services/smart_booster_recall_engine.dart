import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'booster_context_evaluator.dart';
import 'booster_suggestion_stats_service.dart';

/// Detects ignored boosters and suggests them again after a cooldown.
class SmartBoosterRecallEngine {
  final BoosterContextEvaluator evaluator;

  SmartBoosterRecallEngine({BoosterContextEvaluator? evaluator})
      : evaluator = evaluator ?? const BoosterContextEvaluator();

  static final SmartBoosterRecallEngine instance = SmartBoosterRecallEngine();

  static const String _prefsKey = 'smart_booster_recall';

  final Map<String, DateTime> _dismissed = <String, DateTime>{};
  bool _loaded = false;

  /// Clears cached data for tests.
  void resetForTest() {
    _loaded = false;
    _dismissed.clear();
  }

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is Map) {
          data.forEach((key, value) {
            final ts = DateTime.tryParse(value.toString());
            if (ts != null) _dismissed[key.toString()] = ts;
          });
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        for (final e in _dismissed.entries) e.key: e.value.toIso8601String(),
      }),
    );
  }

  Duration _cooldownFor(String type) => const Duration(hours: 48);

  /// Records that a booster of [type] was dismissed.
  Future<void> recordDismissed(String type, {DateTime? timestamp}) async {
    if (type.isEmpty) return;
    await _load();
    _dismissed[type] = timestamp ?? DateTime.now();
    await _save();
    await BoosterSuggestionStatsService.instance.recordDismissed(type);
  }

  /// Returns booster types whose dismissal cooldown has expired and are still relevant.
  Future<List<String>> getRecallableTypes(DateTime now) async {
    await _load();
    final result = <String>[];
    for (final entry in _dismissed.entries) {
      final cooldown = _cooldownFor(entry.key);
      if (!entry.value.add(cooldown).isAfter(now)) {
        if (await evaluator.isRelevant(entry.key)) {
          result.add(entry.key);
        }
      }
    }
    return result;
  }
}
