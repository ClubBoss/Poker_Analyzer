import 'package:shared_preferences/shared_preferences.dart';
import 'lesson_track_meta_service.dart';
import 'lesson_streak_engine.dart';
import 'lesson_progress_service.dart';

class LessonTrackUnlockEngine {
  LessonTrackUnlockEngine._();
  static final LessonTrackUnlockEngine instance = LessonTrackUnlockEngine._();

  static const String defaultTrackId = 'mtt_pro';
  static const String _prefsKey = 'unlocked_tracks';
  static const String _xpKey = 'xp_total';

  final Map<String, String> _prereq = {
    'live_exploit': 'mtt_pro',
    'leak_fixer': 'live_exploit',
  };

  final Map<String, int> _streakReq = {
    'leak_fixer': 5,
  };

  final Map<String, int> _xpReq = {
    'live_exploit': 500,
    'leak_fixer': 1000,
  };

  final Map<String, int> _stepReq = {
    'live_exploit': 5,
  };

  Future<List<String>> _loadUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? <String>[];
    if (!list.contains(defaultTrackId)) list.add(defaultTrackId);
    return list;
  }

  Future<void> _saveUnlocked(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, ids);
  }

  Future<bool> _meetsConditions(String id) async {
    final prereq = _prereq[id];
    if (prereq != null) {
      final meta = await LessonTrackMetaService.instance.load(prereq);
      if (meta?.completedAt == null) return false;
    }

    final streakReq = _streakReq[id];
    if (streakReq != null) {
      final streak = await LessonStreakEngine.instance.getCurrentStreak();
      if (streak < streakReq) return false;
    }

    final xpReq = _xpReq[id];
    if (xpReq != null) {
      final prefs = await SharedPreferences.getInstance();
      final xp = prefs.getInt(_xpKey) ?? 0;
      if (xp < xpReq) return false;
    }

    final stepReq = _stepReq[id];
    if (stepReq != null) {
      final steps = await LessonProgressService.instance.getCompletedSteps();
      if (steps.length < stepReq) return false;
    }

    return true;
  }

  Future<bool> isUnlocked(String trackId) async {
    if (trackId == defaultTrackId) return true;
    final ids = await _loadUnlocked();
    if (ids.contains(trackId)) return true;
    final ok = await _meetsConditions(trackId);
    if (ok) {
      ids.add(trackId);
      await _saveUnlocked(ids);
    }
    return ok;
  }

  Future<void> markUnlocked(String trackId) async {
    final ids = await _loadUnlocked();
    if (!ids.contains(trackId)) {
      ids.add(trackId);
      await _saveUnlocked(ids);
    }
  }

  Future<List<String>> getUnlockedTrackIds() async {
    final ids = await _loadUnlocked();
    for (final id in _prereq.keys) {
      if (!ids.contains(id) && await _meetsConditions(id)) {
        ids.add(id);
      }
    }
    await _saveUnlocked(ids);
    return ids;
  }

  Future<bool> shouldShowLockedBadge(String trackId) async {
    return !(await isUnlocked(trackId));
  }
}
