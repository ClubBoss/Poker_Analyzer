import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';

/// Limits reward drops based on recent frequency.
class DecayRewardFatigueLimiter {
  DecayRewardFatigueLimiter._();
  static final DecayRewardFatigueLimiter instance =
      DecayRewardFatigueLimiter._();

  static const String _prefsKey = 'decay_reward_fatigue_log';
  static const int _maxEntries = 10;
  static const Duration _minInterval = Duration(minutes: 15);
  static const Duration _hour = Duration(hours: 1);

  List<DateTime> _log = [];
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is List) {
          _log = data
              .whereType<String>()
              .map((e) => DateTime.tryParse(e))
              .whereType<DateTime>()
              .toList();
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode([for (final d in _log) d.toIso8601String()]),
    );
  }

  /// Returns true if a reward can be triggered now.
  Future<bool> canTriggerRewardNow() async {
    await _load();
    final now = DateTime.now();
    _log = _log.where((d) => now.difference(d) < _hour).toList();
    if (_log.isNotEmpty && now.difference(_log.first) < _minInterval) {
      await _save();
      return false;
    }
    final recentHour = _log.where((d) => now.difference(d) < _hour).length;
    if (recentHour >= 3) {
      await _save();
      return false;
    }
    await _save();
    return true;
  }

  /// Registers that a reward was dropped now.
  Future<void> registerRewardDrop() async {
    await _load();
    _log.insert(0, DateTime.now());
    if (_log.length > _maxEntries) {
      _log.removeRange(_maxEntries, _log.length);
    }
    await _save();
  }
}
