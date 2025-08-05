import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which theory mini-lessons were recalled during a session.
class TheoryRecallImpactTracker {
  TheoryRecallImpactTracker._();

  /// Singleton instance.
  static final TheoryRecallImpactTracker instance =
      TheoryRecallImpactTracker._();

  static const String _prefsKey = 'theory_recall_log';
  static const int maxEntries = 500;

  final List<_Entry> _logs = <_Entry>[];
  SharedPreferences? _prefs;

  /// Loads persisted logs. Should be called on app startup.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final jsonString = _prefs!.getString(_prefsKey);
    if (jsonString != null) {
      final List<dynamic> data = json.decode(jsonString) as List<dynamic>;
      final Iterable<Map<String, dynamic>> items = data
          .cast<Map<String, dynamic>>()
          .skip(data.length > maxEntries ? data.length - maxEntries : 0);
      _logs
        ..clear()
        ..addAll(items.map(_Entry.fromJson));
    }
  }

  /// Records that a lesson [lessonId] for [tag] was viewed.
  Future<void> record(String tag, String lessonId) async {
    final norm = tag.trim();
    if (norm.isEmpty) return;
    _logs.add(
      _Entry(tag: norm, lessonId: lessonId, timestamp: DateTime.now()),
    );
    if (_logs.length > maxEntries) {
      _logs.removeRange(0, _logs.length - maxEntries);
    }
    await _persist();
  }

  Future<void> _persist() async {
    if (_prefs == null) return;
    final data = _logs.map((e) => e.toJson()).toList();
    await _prefs!.setString(_prefsKey, json.encode(data));
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
      _logs.map(TheoryRecallImpactEntry.fromEntry).toList();

  /// Clears recorded data. Intended for testing.
  void reset({bool clearPrefs = true}) {
    _logs.clear();
    if (clearPrefs) {
      _prefs?.remove(_prefsKey);
    }
  }
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

  factory TheoryRecallImpactEntry.fromEntry(_Entry e) => TheoryRecallImpactEntry(
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

  factory _Entry.fromJson(Map<String, dynamic> json) => _Entry(
        tag: json['tag'] as String,
        lessonId: json['lessonId'] as String,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'tag': tag,
        'lessonId': lessonId,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };
}
