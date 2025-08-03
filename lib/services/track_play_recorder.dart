import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';
import '../models/track_play_history.dart';

/// Records usage of generated training tracks for progress tracking.
class TrackPlayRecorder {
  TrackPlayRecorder._();
  static final TrackPlayRecorder instance = TrackPlayRecorder._();

  static const _prefsKey = 'track_play_history';

  final List<TrackPlayHistory> _history = [];
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is List) {
          _history.addAll(data.whereType<Map>().map((e) =>
              TrackPlayHistory.fromJson(Map<String, dynamic>.from(e))));
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode([for (final h in _history) h.toJson()]),
    );
  }

  /// Logs start of a track play session for [goalId].
  Future<void> recordStart(String goalId) async {
    await _load();
    _history.insert(
      0,
      TrackPlayHistory(goalId: goalId, startedAt: DateTime.now()),
    );
    if (_history.length > 100) _history.removeRange(100, _history.length);
    await _save();
  }

  /// Logs completion of a track play session for [goalId].
  Future<void> recordCompletion(
    String goalId, {
    required double accuracy,
    required int mistakes,
  }) async {
    await _load();
    final index =
        _history.indexWhere((e) => e.goalId == goalId && e.completedAt == null);
    final now = DateTime.now();
    if (index != -1) {
      final entry = _history[index];
      _history[index] = TrackPlayHistory(
        goalId: entry.goalId,
        startedAt: entry.startedAt,
        completedAt: now,
        accuracy: accuracy,
        mistakeCount: mistakes,
      );
    } else {
      _history.insert(
        0,
        TrackPlayHistory(
          goalId: goalId,
          startedAt: now,
          completedAt: now,
          accuracy: accuracy,
          mistakeCount: mistakes,
        ),
      );
    }
    if (_history.length > 100) _history.removeRange(100, _history.length);
    await _save();
  }

  /// Returns stored track play history, most recent first.
  Future<List<TrackPlayHistory>> getHistory() async {
    await _load();
    return List<TrackPlayHistory>.unmodifiable(_history);
  }
}
