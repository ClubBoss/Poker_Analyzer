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
                Map<String, dynamic>.from(e),
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
  Future<List<TheoryAutoInjectionLogEntry>> getRecentLogs({
    int limit = 50,
  }) async {
    await _load();
    return List.unmodifiable(_logs.take(limit));
  }

  /// Returns the total number of logged injections.
  Future<int> getTotalInjectionCount() async {
    await _load();
    return _logs.length;
  }

  /// Returns the number of injections per day for the last [days] days.
  ///
  /// Keys are ISO-8601 date strings (YYYY-MM-DD) ordered chronologically.
  Future<Map<String, int>> getDailyInjectionCounts({int days = 7}) async {
    await _load();
    final now = DateTime.now();
    final counts = <DateTime, int>{};

    for (final log in _logs) {
      final date = DateTime(
        log.timestamp.year,
        log.timestamp.month,
        log.timestamp.day,
      );
      if (now.difference(date).inDays >= days) {
        break;
      }
      counts[date] = (counts[date] ?? 0) + 1;
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return {
      for (final e in entries)
        e.key.toIso8601String().split('T').first: e.value,
    };
  }

  /// Returns the most injected lessons limited by [limit].
  ///
  /// Map keys are lesson ids ordered by descending injection count.
  Future<Map<String, int>> getTopLessonInjections({int limit = 5}) async {
    await _load();
    final counts = <String, int>{};
    for (final log in _logs) {
      counts[log.lessonId] = (counts[log.lessonId] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in entries.take(limit)) e.key: e.value};
  }

  /// Resets in-memory cache for testing.
  void resetForTest() {
    _loaded = false;
    _logs.clear();
  }
}
