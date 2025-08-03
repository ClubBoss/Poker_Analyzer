
/// Records the sequential trail of visited theory lessons.
class TheoryLessonTrailTracker {
  static const _prefsKey = 'theory_lesson_trail';

  TheoryLessonTrailTracker._({this.recentFirst = true});
  static final TheoryLessonTrailTracker instance = TheoryLessonTrailTracker._();

  /// If true, [recordVisit] inserts new lesson ids at the beginning of the trail.
  /// When false, ids are appended to the end.
  final bool recentFirst;

  final List<String> _trail = <String>[];
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await PreferencesService.getInstance();
    final list = prefs.getStringList(_prefsKey);
    if (list != null) _trail.addAll(list);
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setStringList(_prefsKey, _trail);
  }

  /// Adds [lessonId] to the trail and persists it.
  Future<void> recordVisit(String lessonId) async {
    await _load();
    if (recentFirst) {
      _trail.insert(0, lessonId);
    } else {
      _trail.add(lessonId);
    }
    await _save();
  }

  /// Returns up to [limit] recent lesson ids in the stored order.
  List<String> getTrail({int limit = 10}) {
    final l = limit <= 0 || limit >= _trail.length ? _trail : _trail.sublist(0, limit);
    return List<String>.from(l);
  }

  /// Returns the most recently recorded lesson id, or null if empty.
  String? getLastVisited() => _trail.isEmpty ? null : _trail.first;

  /// Clears the stored trail.
  Future<void> clearTrail() async {
    await _load();
    _trail.clear();
    final prefs = await PreferencesService.getInstance();
    await prefs.remove(_prefsKey);
  }
}
