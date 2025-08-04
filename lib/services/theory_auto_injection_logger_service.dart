import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/theory_auto_injection_log_entry.dart';

/// Records automatic theory injection events for decayed spots.
class TheoryAutoInjectionLoggerService {
  TheoryAutoInjectionLoggerService._();
  static final instance = TheoryAutoInjectionLoggerService._();

  static const String _prefsKey = 'auto_theory_injection_log';

  final List<TheoryAutoInjectionLogEntry> _logs = [];
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is List) {
          _logs.addAll(
            data.whereType<Map>().map(
                  (e) => TheoryAutoInjectionLogEntry.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                ),
          );
          _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode([for (final l in _logs) l.toJson()]),
    );
  }

  /// Logs an automatic injection of [lessonId] for [spotId] at [timestamp].
  Future<void> logAutoInjection({
    required String spotId,
    required String lessonId,
    required DateTime timestamp,
  }) async {
    await _load();
    _logs.insert(
      0,
      TheoryAutoInjectionLogEntry(
        spotId: spotId,
        lessonId: lessonId,
        timestamp: timestamp,
      ),
    );
    if (_logs.length > 200) _logs.removeRange(200, _logs.length);
    await _save();
  }

  /// Returns recent logs, most recent first.
  Future<List<TheoryAutoInjectionLogEntry>> getRecentLogs({int limit = 50}) async {
    await _load();
    return List.unmodifiable(_logs.take(limit));
  }

  /// Resets in-memory cache for testing.
  void resetForTest() {
    _loaded = false;
    _logs.clear();
  }
}
