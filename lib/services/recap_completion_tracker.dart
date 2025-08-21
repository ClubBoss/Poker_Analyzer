import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../models/recap_completion_log.dart';

/// Records completion of recap mini lessons for engagement analytics.
class RecapCompletionTracker {
  RecapCompletionTracker._();
  static final RecapCompletionTracker instance = RecapCompletionTracker._();

  static const String _prefsKey = 'recap_completion_logs';

  final List<RecapCompletionLog> _logs = [];
  bool _loaded = false;

  final StreamController<RecapCompletionLog> _ctrl =
      StreamController<RecapCompletionLog>.broadcast();

  /// Stream of newly logged recap completions.
  Stream<RecapCompletionLog> get onCompletion => _ctrl.stream;

  /// Clears cached data for testing.
  void resetForTest() {
    _loaded = false;
    _logs.clear();
  }

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
                  (e) =>
                      RecapCompletionLog.fromJson(Map<String, dynamic>.from(e)),
                ),
          );
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

  /// Logs a completed recap lesson.
  Future<void> logCompletion(
    String lessonId,
    String tag,
    Duration duration, {
    DateTime? timestamp,
  }) async {
    await _load();
    final log = RecapCompletionLog(
      lessonId: lessonId,
      tag: tag,
      timestamp: timestamp ?? DateTime.now(),
      duration: duration,
    );
    _logs.insert(0, log);
    if (_logs.length > 200) _logs.removeRange(200, _logs.length);
    await _save();
    _ctrl.add(log);
  }

  /// Returns completions within [window] sorted newest first.
  Future<List<RecapCompletionLog>> getRecentCompletions({
    Duration window = const Duration(days: 7),
  }) async {
    await _load();
    final cutoff = DateTime.now().subtract(window);
    final list = _logs.where((e) => e.timestamp.isAfter(cutoff));
    return List<RecapCompletionLog>.unmodifiable(list);
  }

  /// Frequency of completions per tag within [window].
  Future<Map<String, int>> tagFrequency({
    Duration window = const Duration(days: 7),
  }) async {
    final list = await getRecentCompletions(window: window);
    final map = <String, int>{};
    for (final l in list) {
      map[l.tag] = (map[l.tag] ?? 0) + 1;
    }
    return map;
  }
}
