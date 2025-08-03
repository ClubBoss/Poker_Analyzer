import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';


/// Remembers recap dismissals per lesson or tag and throttles prompts
/// with an adaptive cooldown that increases on repeated dismissals.
class SmartTheoryRecapDismissalMemory {
  SmartTheoryRecapDismissalMemory._();
  static final SmartTheoryRecapDismissalMemory instance =
      SmartTheoryRecapDismissalMemory._();

  static const _prefsKey = 'smart_theory_recap_dismissals_v2';

  final Map<String, _DismissInfo> _cache = {};
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is Map) {
          data.forEach((key, value) {
            if (value is Map) {
              final info = _DismissInfo.fromJson(Map<String, dynamic>.from(value));
              _cache[key.toString()] = info;
            }
          });
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({for (final e in _cache.entries) e.key: e.value.toJson()}),
    );
  }

  Future<_DismissInfo?> _get(String key) async {
    await _load();
    final info = _cache[key];
    if (info != null &&
        DateTime.now().difference(info.timestamp) > const Duration(days: 3)) {
      _cache.remove(key);
      await _save();
      return null;
    }
    return info;
  }

  /// Returns true if recap prompts for [key] should be throttled.
  /// The throttle duration grows with each consecutive dismissal.
  Future<bool> shouldThrottle(String key) async {
    final info = await _get(key);
    if (info == null) return false;
    final cooldown = Duration(hours: 12 * info.count);
    return DateTime.now().difference(info.timestamp) < cooldown;
  }

  /// Registers a dismissal for [key] and updates persistent storage.
  Future<void> registerDismissal(String key) async {
    await _load();
    final info = await _get(key);
    final updated = _DismissInfo(
      count: (info?.count ?? 0) + 1,
      timestamp: DateTime.now(),
    );
    _cache[key] = updated;
    await _save();
  }

  /// Returns current dismiss counts for debugging.
  Future<Map<String, int>> debugCounts() async {
    await _load();
    final result = <String, int>{};
    final now = DateTime.now();
    _cache.removeWhere(
      (_, info) => now.difference(info.timestamp) > const Duration(days: 3),
    );
    for (final e in _cache.entries) {
      result[e.key] = e.value.count;
    }
    return result;
  }

  /// Clears cached data for testing purposes.
  void resetForTest() {
    _loaded = false;
    _cache.clear();
  }
}

class _DismissInfo {
  final int count;
  final DateTime timestamp;

  const _DismissInfo({required this.count, required this.timestamp});

  Map<String, dynamic> toJson() => {
        'count': count,
        'ts': timestamp.toIso8601String(),
      };

  factory _DismissInfo.fromJson(Map<String, dynamic> json) {
    final ts = DateTime.tryParse(json['ts'] as String? ?? '') ?? DateTime.now();
    final count = (json['count'] as num?)?.toInt() ?? 0;
    return _DismissInfo(count: count, timestamp: ts);
  }
}
