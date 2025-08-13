import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Blocks reinjection of boosters that were recently dismissed or completed.
class BoosterCooldownBlockerService {
  BoosterCooldownBlockerService._();
  static final BoosterCooldownBlockerService instance =
      BoosterCooldownBlockerService._();

  static const String _prefsKey = 'booster_cooldown_blocker';

  Map<String, _Record> _cache = {};
  bool _loaded = false;

  /// Clears cached data for testing purposes.
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
              if (e.value is Map)
                e.key.toString():
                    _Record.fromJson(Map<String, dynamic>.from(e.value as Map))
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
      jsonEncode({for (final e in _cache.entries) e.key: e.value.toJson()}),
    );
  }

  Duration _cooldownFor(String type) {
    switch (type) {
      case 'recap':
        return const Duration(hours: 3);
      case 'skill_gap':
        return const Duration(hours: 6);
      case 'goal':
        return const Duration(hours: 12);
    }
    return const Duration(hours: 3);
  }

  /// Marks a dismissal of [type] at current time.
  Future<void> markDismissed(String type) async {
    await _load();
    final entry = _cache[type] ?? const _Record();
    _cache[type] = entry.copyWith(dismissed: DateTime.now());
    await _save();
  }

  /// Marks a completion of [type] at current time.
  Future<void> markCompleted(String type) async {
    await _load();
    final entry = _cache[type] ?? const _Record();
    _cache[type] = entry.copyWith(completed: DateTime.now());
    await _save();
  }

  /// Returns `true` if [type] is still under cooldown.
  Future<bool> isCoolingDown(String type) async {
    await _load();
    final entry = _cache[type];
    if (entry == null) return false;
    final cooldown = _cooldownFor(type);
    final now = DateTime.now();
    if (entry.dismissed != null &&
        now.difference(entry.dismissed!) < cooldown) {
      return true;
    }
    if (entry.completed != null &&
        now.difference(entry.completed!) < cooldown) {
      return true;
    }
    return false;
  }
}

class _Record {
  final DateTime? dismissed;
  final DateTime? completed;

  const _Record({this.dismissed, this.completed});

  _Record copyWith({DateTime? dismissed, DateTime? completed}) {
    return _Record(
      dismissed: dismissed ?? this.dismissed,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
        if (dismissed != null) 'd': dismissed!.toIso8601String(),
        if (completed != null) 'c': completed!.toIso8601String(),
      };

  factory _Record.fromJson(Map<String, dynamic> json) {
    return _Record(
      dismissed: DateTime.tryParse(json['d'] as String? ?? ''),
      completed: DateTime.tryParse(json['c'] as String? ?? ''),
    );
  }
}
