import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Aggregates review history per lesson to enable recall analytics.
class LessonReviewInsightsService {
  static const String _prefsKey = 'lesson_review_history';

  LessonReviewInsightsService._();
  static final LessonReviewInsightsService instance =
      LessonReviewInsightsService._();

  bool _loaded = false;
  Map<String, List<_LessonReviewEntry>> _history = {};

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is Map) {
          _history = data.map((key, value) {
            final list =
                (value as List?)
                    ?.whereType<Map>()
                    .map(
                      (e) => _LessonReviewEntry.fromJson(
                        Map<String, dynamic>.from(e),
                      ),
                    )
                    .toList() ??
                [];
            list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            return MapEntry(key as String, list);
          });
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _history.map(
      (key, value) => MapEntry(key, value.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(_prefsKey, jsonEncode(data));
  }

  /// Records a review attempt for [lessonId] with [success] outcome.
  Future<void> recordReview(String lessonId, {required bool success}) async {
    await _load();
    final list = _history.putIfAbsent(lessonId, () => <_LessonReviewEntry>[]);
    list.add(_LessonReviewEntry(timestamp: DateTime.now(), success: success));
    if (list.length > 100) {
      list.removeRange(0, list.length - 100);
    }
    await _save();
  }

  /// Returns review timestamps for [lessonId], oldest first.
  Future<List<DateTime>> getReviewHistory(String lessonId) async {
    await _load();
    final list = _history[lessonId];
    if (list == null) return const [];
    return List<DateTime>.unmodifiable(list.map((e) => e.timestamp));
  }

  /// Returns total number of reviews for [lessonId].
  Future<int> getTotalReviews(String lessonId) async {
    await _load();
    return _history[lessonId]?.length ?? 0;
  }

  /// Returns average interval between reviews for [lessonId].
  /// Returns `null` if fewer than two reviews exist.
  Future<Duration?> getAverageInterval(String lessonId) async {
    final history = await getReviewHistory(lessonId);
    if (history.length < 2) return null;
    Duration total = Duration.zero;
    for (var i = 1; i < history.length; i++) {
      total += history[i].difference(history[i - 1]);
    }
    return total ~/ (history.length - 1);
  }

  /// Returns last review date for [lessonId] if any.
  Future<DateTime?> getLastReviewDate(String lessonId) async {
    final history = await getReviewHistory(lessonId);
    if (history.isEmpty) return null;
    return history.last;
  }

  /// Returns number of successful reviews for [lessonId].
  Future<int> getSuccessCount(String lessonId) async {
    await _load();
    return _history[lessonId]?.where((e) => e.success).length ?? 0;
  }
}

class _LessonReviewEntry {
  final DateTime timestamp;
  final bool success;

  _LessonReviewEntry({required this.timestamp, required this.success});

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'success': success,
  };

  factory _LessonReviewEntry.fromJson(Map<String, dynamic> json) {
    return _LessonReviewEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      success: json['success'] == true,
    );
  }
}
