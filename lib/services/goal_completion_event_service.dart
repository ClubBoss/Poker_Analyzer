import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';


import '../models/goal_completion_event.dart';
import '../models/goal_progress.dart';
import 'goal_completion_engine.dart';
import 'goal_engagement_tracker.dart';
import '../models/goal_engagement.dart';

class GoalCompletionEventService {
  GoalCompletionEventService._();
  static final instance = GoalCompletionEventService._();

  static const _prefsKey = 'goal_completion_events';

  final Map<String, DateTime> _events = {};
  bool _loaded = false;

  Map<String, DateTime> get events => Map.unmodifiable(_events);

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _events.clear();
        for (final entry in map.entries) {
          final ts = DateTime.tryParse(entry.value as String? ?? '');
          if (ts != null) _events[entry.key] = ts;
        }
      } catch (_) {
        _events.clear();
      }
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await PreferencesService.getInstance();
    final map = {
      for (final e in _events.entries) e.key: e.value.toIso8601String()
    };
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  Future<void> logIfNew(GoalProgress progress) async {
    await _load();
    final tag = progress.tag.trim().toLowerCase();
    if (_events.containsKey(tag)) return;
    if (!GoalCompletionEngine.instance.isGoalCompleted(progress)) return;
    final now = DateTime.now();
    _events[tag] = now;
    await _save();
    await GoalEngagementTracker.instance.log(
      GoalEngagement(tag: tag, action: 'completed', timestamp: now),
    );
  }

  DateTime? completedAt(String tag) {
    final key = tag.trim().toLowerCase();
    return _events[key];
  }

  Future<List<GoalCompletionEvent>> getAllEvents() async {
    await _load();
    final list = [
      for (final e in _events.entries)
        GoalCompletionEvent(tag: e.key, timestamp: e.value)
    ]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }
}
