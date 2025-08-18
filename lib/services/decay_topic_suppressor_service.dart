import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'mini_lesson_library_service.dart';
import 'mini_lesson_progress_tracker.dart';
import 'theory_tag_decay_tracker.dart';

/// Suppresses boosters and reminders for tags the user repeatedly ignores.
class DecayTopicSuppressorService {
  final MiniLessonLibraryService lessons;
  final MiniLessonProgressTracker progress;
  final TheoryTagDecayTracker decay;

  DecayTopicSuppressorService({
    MiniLessonLibraryService? lessons,
    MiniLessonProgressTracker? progress,
    TheoryTagDecayTracker? decay,
  }) : lessons = lessons ?? MiniLessonLibraryService.instance,
       progress = progress ?? MiniLessonProgressTracker.instance,
       decay = decay ?? TheoryTagDecayTracker();

  static final DecayTopicSuppressorService instance =
      DecayTopicSuppressorService();

  static const String _prefsKey = 'ignored_decay_tags_v2';
  static const String _decayKey = 'ignored_decay_tags_since';

  final Map<String, int> _ignored = {};
  final Map<String, DateTime> _since = {};
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
            _ignored[key.toString()] = (value as num?)?.toInt() ?? 0;
          });
        }
      } catch (_) {}
    }
    final rawSince = prefs.getString(_decayKey);
    if (rawSince != null) {
      try {
        final data = jsonDecode(rawSince);
        if (data is Map) {
          data.forEach((key, value) {
            final ts = DateTime.tryParse(value.toString());
            if (ts != null) _since[key.toString()] = ts;
          });
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_ignored));
    await prefs.setString(
      _decayKey,
      jsonEncode({
        for (final e in _since.entries) e.key: e.value.toIso8601String(),
      }),
    );
  }

  Future<bool> _hasEngagement(String tag) async {
    await lessons.loadAll();
    final list = lessons.findByTags([tag]);
    for (final lesson in list) {
      final ts = await progress.lastViewed(lesson.id);
      if (ts != null) return true;
    }
    return false;
  }

  Future<void> _updateDecay(String tag, double score) async {
    if (score > 60) {
      _since.putIfAbsent(tag, () => DateTime.now());
    } else {
      _since.remove(tag);
    }
  }

  /// Records another ignored occurrence of [tag].
  Future<void> recordIgnored(String tag) async {
    await _load();
    final key = tag.trim().toLowerCase();
    if (key.isEmpty) return;
    _ignored.update(key, (v) => v + 1, ifAbsent: () => 1);
    await _save();
  }

  /// Clears suppression state for [tag].
  Future<void> reset(String tag) async {
    await _load();
    final changed = _ignored.remove(tag) != null || _since.remove(tag) != null;
    if (changed) await _save();
  }

  /// Returns true if [tag] should be suppressed.
  Future<bool> shouldSuppress(String tag) async {
    final key = tag.trim().toLowerCase();
    if (key.isEmpty) return false;
    await _load();

    final engaged = await _hasEngagement(key);
    if (engaged) {
      await reset(key);
      return false;
    }

    final scores = await decay.computeDecayScores();
    final score = scores[key] ?? 0.0;
    await _updateDecay(key, score);
    final since = _since[key];
    final longDecay =
        since != null &&
        DateTime.now().difference(since) > const Duration(days: 21);

    final ignoredCount = _ignored[key] ?? 0;
    final suppress = ignoredCount >= 2 && longDecay;
    if (suppress) await _save();
    return suppress;
  }
}
