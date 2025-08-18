import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Background scheduler for auto-repeating recap lessons.
class RecapAutoRepeatScheduler {
  RecapAutoRepeatScheduler._();
  static final RecapAutoRepeatScheduler instance = RecapAutoRepeatScheduler._();

  static const String _prefsKey = 'recap_auto_repeat_schedule';

  final Map<String, DateTime> _cache = {};
  bool _loaded = false;

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
            if (ts != null) _cache[key.toString()] = ts;
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
        for (final e in _cache.entries) e.key: e.value.toIso8601String(),
      }),
    );
  }

  /// Schedules [lessonId] to resurface after [delay].
  Future<void> scheduleRepeat(String lessonId, Duration delay) async {
    if (lessonId.isEmpty) return;
    await _load();
    _cache[lessonId] = DateTime.now().add(delay);
    await _save();
  }

  Future<List<String>> _consumeDueIds() async {
    await _load();
    final now = DateTime.now();
    final due = <String>[];
    final remove = <String>[];
    _cache.forEach((id, ts) {
      if (!ts.isAfter(now)) {
        due.add(id);
        remove.add(id);
      }
    });
    for (final id in remove) {
      _cache.remove(id);
    }
    if (remove.isNotEmpty) await _save();
    return due;
  }

  /// Periodically emits lesson ids whose repeat delay elapsed.
  Stream<List<String>> getPendingRecapIds({
    Duration interval = const Duration(hours: 1),
  }) async* {
    yield await _consumeDueIds();
    yield* Stream.periodic(
      interval,
      (_) => _consumeDueIds(),
    ).asyncMap((f) => f);
  }

  /// Clears cached data for tests.
  void resetForTest() {
    _loaded = false;
    _cache.clear();
  }
}
