import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'booster_suggestion_stats_service.dart';

/// Dynamically schedules boosters based on recent user interactions.
class BoosterCooldownScheduler {
  BoosterCooldownScheduler._();
  static final BoosterCooldownScheduler instance = BoosterCooldownScheduler._();

  static const String _prefsKey = 'booster_cooldown_scheduler';

  Map<String, List<_Event>> _cache = {};
  bool _loaded = false;

  /// Clears cached data for testing.
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
              if (e.value is List)
                e.key.toString(): [
                  for (final v in e.value as List)
                    if (v is Map) _Event.fromJson(Map<String, dynamic>.from(v))
                ]
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
      jsonEncode({
        for (final e in _cache.entries)
          e.key: [for (final ev in e.value) ev.toJson()]
      }),
    );
  }

  void _cleanup() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    _cache.removeWhere((_, list) {
      list.removeWhere((e) => e.timestamp.isBefore(cutoff));
      return list.isEmpty;
    });
  }

  Future<void> _addEvent(String type, String kind, [DateTime? ts]) async {
    await _load();
    final list = _cache[type] ?? <_Event>[];
    list.insert(0, _Event(kind, ts ?? DateTime.now()));
    _cache[type] = list;
    _cleanup();
    await _save();
    switch (kind) {
      case 'suggested':
        await BoosterSuggestionStatsService.instance.recordSuggested(type);
        break;
      case 'accepted':
        await BoosterSuggestionStatsService.instance.recordAccepted(type);
        break;
      case 'dismissed':
        await BoosterSuggestionStatsService.instance.recordDismissed(type);
        break;
    }
  }

  /// Records that a booster of [type] was suggested now.
  Future<void> recordSuggested(String type, {DateTime? timestamp}) =>
      _addEvent(type, 'suggested', timestamp);

  /// Records that a booster of [type] was accepted now.
  Future<void> recordAccepted(String type, {DateTime? timestamp}) =>
      _addEvent(type, 'accepted', timestamp);

  /// Records that a booster of [type] was dismissed now.
  Future<void> recordDismissed(String type, {DateTime? timestamp}) =>
      _addEvent(type, 'dismissed', timestamp);

  /// Returns `true` if [boosterType] should be suppressed temporarily.
  Future<bool> isCoolingDown(String boosterType) async {
    await _load();
    _cleanup();
    await _save();
    final list = _cache[boosterType];
    if (list == null || list.isEmpty) return false;
    final now = DateTime.now();

    // Overuse check: suggested 5+ times in last 24h
    final recentSuggestions = list.where((e) {
      return e.kind == 'suggested' &&
          now.difference(e.timestamp) < const Duration(hours: 24);
    }).length;
    if (recentSuggestions >= 5) return true;

    // Most recent accepted/dismissed times
    DateTime? lastAccepted;
    DateTime? lastDismissed;
    for (final e in list) {
      if (lastAccepted == null && e.kind == 'accepted')
        lastAccepted = e.timestamp;
      if (lastDismissed == null && e.kind == 'dismissed') {
        lastDismissed = e.timestamp;
      }
      if (lastAccepted != null && lastDismissed != null) break;
    }

    if (lastDismissed != null &&
        (lastAccepted == null || lastDismissed.isAfter(lastAccepted)) &&
        now.difference(lastDismissed) < const Duration(hours: 6)) {
      return true;
    }

    // Consecutive dismissal streak
    var streak = 0;
    for (final e in list) {
      if (e.kind == 'dismissed') {
        streak++;
      } else if (e.kind == 'suggested') {
        break;
      } else {
        break;
      }
    }
    if (streak >= 3) {
      final cooldownHours = 6 * pow(2, streak - 3).toInt();
      final last = list.first.timestamp;
      if (now.difference(last) < Duration(hours: cooldownHours)) {
        return true;
      }
    }
    return false;
  }
}

class _Event {
  final String kind;
  final DateTime timestamp;

  _Event(this.kind, this.timestamp);

  Map<String, dynamic> toJson() => {
        'k': kind,
        't': timestamp.toIso8601String(),
      };

  factory _Event.fromJson(Map<String, dynamic> json) => _Event(
        json['k'] as String? ?? '',
        DateTime.tryParse(json['t'] as String? ?? '') ?? DateTime.now(),
      );
}
