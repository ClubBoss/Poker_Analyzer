import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/recall_success_entry.dart';
import 'decay_tag_retention_tracker_service.dart';
import 'recall_success_logger_service.dart';

/// Analyzes how effective theory lessons are at restoring tag recall.
///
/// Each theory review session is recorded via [recordReview]. When recall
/// success is later logged for the same tag, the analyzer compares the decay
/// level before the review with the decay at the moment of success. The
/// difference represents the recall gain for that session.
class TheoryLessonEffectivenessAnalyzerService {
  static const _prefsKey = 'theory_effectiveness_sessions';

  final DecayTagRetentionTrackerService retention;
  final RecallSuccessLoggerService logger;

  const TheoryLessonEffectivenessAnalyzerService({
    this.retention = const DecayTagRetentionTrackerService(),
    RecallSuccessLoggerService? logger,
  }) : logger = logger ?? RecallSuccessLoggerService.instance;

  final List<_ReviewSession> _sessions = [];
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is List) {
          _sessions.addAll(
            data.whereType<Map>().map((e) {
              return _ReviewSession.fromJson(Map<String, dynamic>.from(e));
            }),
          );
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode([for (final s in _sessions) s.toJson()]),
    );
  }

  /// Records a theory review for [tag] and [lessonId].
  ///
  /// The [time] parameter allows tests to control the timestamp.
  Future<void> recordReview(
    String tag,
    String lessonId, {
    DateTime? time,
  }) async {
    final normTag = tag.trim().toLowerCase();
    if (normTag.isEmpty) return;
    final reviewTime = time ?? DateTime.now();
    final preDecay = await retention.getDecayScore(normTag, now: reviewTime);
    await _load();
    _sessions.insert(
      0,
      _ReviewSession(
        tag: normTag,
        lessonId: lessonId,
        time: reviewTime,
        preDecay: preDecay,
      ),
    );
    if (_sessions.length > 200) {
      _sessions.removeRange(200, _sessions.length);
    }
    await _save();
  }

  /// Returns the average recall gain for [tag], or `null` if insufficient data.
  ///
  /// Gain is defined as `preDecay - postDecay` where `postDecay` is the time in
  /// days between the review and the first successful recall after it.
  Future<double?> getAverageTheoryGain(String tag) async {
    final normTag = tag.trim().toLowerCase();
    if (normTag.isEmpty) return null;
    await _load();
    final sessions = _sessions.where((s) => s.tag == normTag).toList();
    if (sessions.isEmpty) return null;

    final successes = await logger.getSuccesses(tag: normTag);
    if (successes.isEmpty) return null;
    successes.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    double total = 0;
    int count = 0;
    for (final s in sessions) {
      final success = successes.firstWhereOrNull(
        (e) => e.timestamp.isAfter(s.time),
      );
      if (success == null) continue;
      final post = success.timestamp.difference(s.time).inDays.toDouble();
      total += s.preDecay - post;
      count++;
    }
    if (count == 0) return null;
    return total / count;
  }

  /// Returns lessons sorted by average recall gain, requiring at least
  /// [minSessions] recorded reviews per lesson.
  Future<Map<String, double>> getTopEffectiveLessons({
    int minSessions = 3,
  }) async {
    await _load();
    if (_sessions.isEmpty) return <String, double>{};

    final successes = await logger.getSuccesses();
    if (successes.isEmpty) return <String, double>{};
    successes.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final byTag = groupBy(successes, (RecallSuccessEntry e) => e.tag);

    final gains = <String, List<double>>{};

    for (final session in _sessions) {
      final list = byTag[session.tag];
      if (list == null) continue;
      final success = list.firstWhereOrNull(
        (e) =>
            e.timestamp.isAfter(session.time) &&
            (e.source == null || e.source == session.lessonId),
      );
      if (success == null) continue;
      final post = success.timestamp.difference(session.time).inDays.toDouble();
      gains
          .putIfAbsent(session.lessonId, () => [])
          .add(session.preDecay - post);
    }

    final result = <String, double>{};
    for (final entry in gains.entries) {
      if (entry.value.length < minSessions) continue;
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      result[entry.key] = avg;
    }

    final sorted = result.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in sorted) e.key: e.value};
  }
}

class _ReviewSession {
  final String tag;
  final String lessonId;
  final DateTime time;
  final double preDecay;

  const _ReviewSession({
    required this.tag,
    required this.lessonId,
    required this.time,
    required this.preDecay,
  });

  Map<String, dynamic> toJson() => {
        'tag': tag,
        'lessonId': lessonId,
        'time': time.toIso8601String(),
        'pre': preDecay,
      };

  factory _ReviewSession.fromJson(Map<String, dynamic> json) => _ReviewSession(
        tag: json['tag'] as String? ?? '',
        lessonId: json['lessonId'] as String? ?? '',
        time:
            DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
        preDecay: (json['pre'] as num?)?.toDouble() ?? 0.0,
      );
}
