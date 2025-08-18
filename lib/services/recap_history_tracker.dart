import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/recap_event.dart';

/// Persistently tracks recap-related events.
class RecapHistoryTracker {
  RecapHistoryTracker._();
  static final RecapHistoryTracker instance = RecapHistoryTracker._();

  static const String _prefsKey = 'recap_history_events';

  final List<RecapEvent> _events = [];
  bool _loaded = false;

  /// Clears cached data for testing purposes.
  void resetForTest() {
    _loaded = false;
    _events.clear();
  }

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is List) {
          _events.addAll(
            data.whereType<Map>().map((e) {
              return RecapEvent.fromJson(Map<String, dynamic>.from(e));
            }),
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
      jsonEncode([for (final e in _events) e.toJson()]),
    );
  }

  /// Logs a recap [eventType] for [lessonId] and [trigger].
  Future<void> logRecapEvent(
    String lessonId,
    String trigger,
    String eventType, {
    DateTime? timestamp,
  }) async {
    await _load();
    _events.insert(
      0,
      RecapEvent(
        lessonId: lessonId,
        trigger: trigger,
        eventType: eventType,
        timestamp: timestamp ?? DateTime.now(),
      ),
    );
    if (_events.length > 200) _events.removeRange(200, _events.length);
    await _save();
  }

  /// Records that a drill was launched for [lessonId].
  Future<void> registerDrillLaunch(String lessonId) async {
    await logRecapEvent(lessonId, 'banner', 'drillLaunch');
  }

  /// Returns history filtered by [lessonId] and [trigger] if provided.
  Future<List<RecapEvent>> getHistory({
    String? lessonId,
    String? trigger,
  }) async {
    await _load();
    Iterable<RecapEvent> list = _events;
    if (lessonId != null) list = list.where((e) => e.lessonId == lessonId);
    if (trigger != null) list = list.where((e) => e.trigger == trigger);
    return List<RecapEvent>.unmodifiable(list);
  }
}
