import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';


import '../models/booster_path_log_entry.dart';
import '../models/booster_tag_history.dart';

/// Stores booster lesson interaction history in local preferences.
class BoosterPathHistoryService {
  BoosterPathHistoryService._();
  static final BoosterPathHistoryService instance = BoosterPathHistoryService._();

  static const String _prefsKey = 'booster_path_logs';

  List<BoosterPathLogEntry> _logs = [];
  bool _loaded = false;

  /// Clears cached data for testing.
  void resetForTest() {
    _loaded = false;
    _logs = [];
  }

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is List) {
          _logs = [
            for (final e in data)
              if (e is Map)
                BoosterPathLogEntry.fromJson(
                    Map<String, dynamic>.from(e))
          ];
          _logs.sort((a, b) => b.shownAt.compareTo(a.shownAt));
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode([for (final l in _logs) l.toJson()]),
    );
  }

  /// Record that [lessonId] with [tag] was shown now.
  Future<void> markShown(String lessonId, String tag) async {
    await _load();
    final entry = BoosterPathLogEntry(
      lessonId: lessonId,
      tag: tag.trim().toLowerCase(),
      shownAt: DateTime.now(),
    );
    _logs.add(entry);
    await _save();
  }

  /// Record that [lessonId] with [tag] was completed now.
  Future<void> markCompleted(String lessonId, String tag) async {
    await _load();
    final normTag = tag.trim().toLowerCase();
    for (var i = _logs.length - 1; i >= 0; i--) {
      final e = _logs[i];
      if (e.lessonId == lessonId && e.tag == normTag && e.completedAt == null) {
        _logs[i] = e.copyWith(completedAt: DateTime.now());
        await _save();
        return;
      }
    }
    _logs.add(BoosterPathLogEntry(
      lessonId: lessonId,
      tag: normTag,
      shownAt: DateTime.now(),
      completedAt: DateTime.now(),
    ));
    await _save();
  }

  /// Returns log entries optionally filtered by [tag]. Most recent first.
  Future<List<BoosterPathLogEntry>> getHistory({String? tag}) async {
    await _load();
    if (tag == null) return List.unmodifiable(_logs);
    final normTag = tag.trim().toLowerCase();
    return List.unmodifiable(_logs.where((e) => e.tag == normTag));
  }

  /// Returns aggregated history keyed by tag.
  Future<Map<String, BoosterTagHistory>> getTagStats() async {
    final logs = await getHistory();
    final map = <String, BoosterTagHistory>{};
    for (final e in logs) {
      final hist = map[e.tag];
      if (hist == null) {
        map[e.tag] = BoosterTagHistory(
          tag: e.tag,
          shownCount: 1,
          startedCount: 0,
          completedCount: e.completedAt != null ? 1 : 0,
          lastInteraction: e.completedAt ?? e.shownAt,
        );
      } else {
        map[e.tag] = hist.copyWith(
          shownCount: hist.shownCount + 1,
          completedCount:
              hist.completedCount + (e.completedAt != null ? 1 : 0),
          lastInteraction: e.completedAt ?? e.shownAt,
        );
      }
    }
    return map;
  }
}
