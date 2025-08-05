/// Tracks which theory mini-lessons were recalled during a session.
class TheoryRecallImpactTracker {
  TheoryRecallImpactTracker._();

  /// Singleton instance.
  static final TheoryRecallImpactTracker instance =
      TheoryRecallImpactTracker._();

  final List<_Entry> _logs = <_Entry>[];

  /// Records that a lesson [lessonId] for [tag] was viewed.
  void record(String tag, String lessonId) {
    final norm = tag.trim();
    if (norm.isEmpty) return;
    _logs.add(_Entry(tag: norm, lessonId: lessonId, timestamp: DateTime.now()));
  }

  /// Returns a map from tag to list of lesson ids viewed for that tag.
  Map<String, List<String>> get tagToLessons {
    final Map<String, List<String>> result = <String, List<String>>{};
    for (final e in _logs) {
      result.putIfAbsent(e.tag, () => <String>[]).add(e.lessonId);
    }
    return result;
  }

  /// Returns the recorded entries in order of occurrence.
  List<TheoryRecallImpactEntry> get entries =>
      _logs.map((e) => TheoryRecallImpactEntry.fromEntry(e)).toList();

  /// Clears recorded data. Intended for testing.
  void reset() => _logs.clear();
}

/// Public view of a recall impact entry.
class TheoryRecallImpactEntry {
  TheoryRecallImpactEntry({
    required this.tag,
    required this.lessonId,
    required this.timestamp,
  });

  final String tag;
  final String lessonId;
  final DateTime timestamp;

  factory TheoryRecallImpactEntry.fromEntry(_Entry e) =>
      TheoryRecallImpactEntry(
        tag: e.tag,
        lessonId: e.lessonId,
        timestamp: e.timestamp,
      );
}

class _Entry {
  _Entry({required this.tag, required this.lessonId, required this.timestamp});

  final String tag;
  final String lessonId;
  final DateTime timestamp;
}
