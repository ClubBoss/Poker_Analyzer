import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/theory_suggestion_engagement_event.dart';

/// Tracks user engagement with automatically suggested theory lessons.
class TheorySuggestionEngagementTrackerService {
  TheorySuggestionEngagementTrackerService._();

  /// Singleton instance.
  static final TheorySuggestionEngagementTrackerService instance =
      TheorySuggestionEngagementTrackerService._();

  static const String _prefsKey = 'theory_suggestion_engagement_events';

  final List<TheorySuggestionEngagementEvent> _events = [];
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    _events
      ..clear()
      ..addAll(raw.map((e) => TheorySuggestionEngagementEvent.fromJson(
          jsonDecode(e) as Map<String, dynamic>)));
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      [for (final e in _events) jsonEncode(e.toJson())],
    );
  }

  Future<void> _log(String lessonId, String action) async {
    await _load();
    _events.add(TheorySuggestionEngagementEvent(
      lessonId: lessonId,
      action: action,
      timestamp: DateTime.now(),
    ));
    await _save();
  }

  /// Records that a lesson suggestion was shown to the user.
  Future<void> lessonSuggested(String lessonId) => _log(lessonId, 'suggested');

  /// Records that the suggested lesson was expanded by the user.
  Future<void> lessonExpanded(String lessonId) => _log(lessonId, 'expanded');

  /// Records that the full lesson was opened by the user.
  Future<void> lessonOpened(String lessonId) => _log(lessonId, 'opened');

  /// Returns a map of lesson ids and their count for the given [action].
  Future<Map<String, int>> countByAction(String action) async {
    await _load();
    final counts = <String, int>{};
    for (final e in _events.where((e) => e.action == action)) {
      counts[e.lessonId] = (counts[e.lessonId] ?? 0) + 1;
    }
    return counts;
  }

  /// Returns all events matching [action].
  Future<List<TheorySuggestionEngagementEvent>> eventsByAction(
      String action) async {
    await _load();
    return _events.where((e) => e.action == action).toList(growable: false);
  }
}
