import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/goal_engagement.dart';

/// Tracks user interactions with training goals.
class GoalEngagementTracker {
  GoalEngagementTracker._();

  /// Singleton instance.
  static final GoalEngagementTracker instance = GoalEngagementTracker._();

  static const String _prefsKey = 'goal_engagement_log';

  final List<GoalEngagement> _events = [];
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    _events
      ..clear()
      ..addAll(raw.map((e) =>
          GoalEngagement.fromJson(jsonDecode(e) as Map<String, dynamic>)));
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      [for (final e in _events) jsonEncode(e.toJson())],
    );
  }

  /// Log a goal engagement event.
  Future<void> log(GoalEngagement event) async {
    await _load();
    _events.add(event);
    await _save();
  }

  /// Returns all logged engagement events.
  Future<List<GoalEngagement>> getAll() async {
    await _load();
    return List.unmodifiable(_events);
  }
}
