import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/lesson_failure.dart';

/// Tracks view and completion stats for theory mini lessons.
class MiniLessonProgressTracker {
  MiniLessonProgressTracker._();
  static final MiniLessonProgressTracker instance =
      MiniLessonProgressTracker._();

  static const String _prefix = 'mini_lesson_progress_';
  static const String _failurePrefix = 'mini_lesson_failure_';

  final Map<String, _MiniProgress> _cache = {};
  final Map<String, List<LessonFailure>> _failureCache = {};
  final StreamController<String> _completedController =
      StreamController<String>.broadcast();

  /// Stream of lesson ids that were marked as completed.
  Stream<String> get onLessonCompleted => _completedController.stream;

  Future<_MiniProgress> _load(String id) async {
    final cached = _cache[id];
    if (cached != null) return cached;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$id');
    if (raw != null) {
      try {
        final map = jsonDecode(raw);
        if (map is Map<String, dynamic>) {
          return _cache[id] = _MiniProgress.fromMap(map);
        }
      } catch (_) {}
    }
    return _cache[id] = _MiniProgress();
  }

  Future<void> _save(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final data = _cache[id] ?? _MiniProgress();
    await prefs.setString('$_prefix$id', jsonEncode(data.toMap()));
  }

  /// Increments view count and updates timestamp for [id].
  Future<void> markViewed(String id) async {
    final data = await _load(id);
    data.viewCount++;
    data.lastViewed = DateTime.now();
    await _save(id);
  }

  /// Marks [id] as completed and updates timestamp.
  Future<void> markCompleted(String id) async {
    final data = await _load(id);
    data.completed = true;
    data.lastViewed = DateTime.now();
    await _save(id);
    _completedController.add(id);
  }

  /// Returns true if [id] was completed.
  Future<bool> isCompleted(String id) async {
    final data = await _load(id);
    return data.completed;
  }

  /// Timestamp of the last view for [id], or null if never viewed.
  Future<DateTime?> lastViewed(String id) async {
    final data = await _load(id);
    return data.lastViewed;
  }

  /// Current view count for [id].
  Future<int> viewCount(String id) async {
    final data = await _load(id);
    return data.viewCount;
  }

  /// Returns the id with the lowest view count from [ids].
  Future<String?> getLeastViewed(List<String> ids) async {
    if (ids.isEmpty) return null;
    String? bestId;
    int? bestCount;
    for (final id in ids) {
      final data = await _load(id);
      final count = data.viewCount;
      if (bestId == null || count < bestCount!) {
        bestId = id;
        bestCount = count;
      }
    }
    return bestId;
  }

  Future<List<LessonFailure>> _loadFailures(String id) async {
    final cached = _failureCache[id];
    if (cached != null) return cached;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_failurePrefix$id');
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is List) {
          final list = <LessonFailure>[];
          for (final e in data) {
            if (e is Map) {
              list.add(LessonFailure.fromJson(Map<String, dynamic>.from(e)));
            }
          }
          return _failureCache[id] = list;
        }
      } catch (_) {}
    }
    return _failureCache[id] = <LessonFailure>[];
  }

  Future<void> _saveFailures(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _failureCache[id] ?? <LessonFailure>[];
    await prefs.setString(
        '$_failurePrefix$id', jsonEncode([for (final f in list) f.toJson()]));
  }

  /// Records a failure for [id] with optional [evLoss].
  Future<void> markFailure(String id, {double evLoss = 0}) async {
    final list = await _loadFailures(id);
    list.insert(0, LessonFailure(timestamp: DateTime.now(), evLoss: evLoss));
    if (list.length > 50) list.removeRange(50, list.length);
    await _saveFailures(id);
  }

  /// Returns recorded failures for [id]. Most recent first.
  Future<List<LessonFailure>> failures(String id) async {
    final list = await _loadFailures(id);
    return List<LessonFailure>.unmodifiable(list);
  }
}

class _MiniProgress {
  int viewCount;
  DateTime? lastViewed;
  bool completed;

  _MiniProgress({this.viewCount = 0, this.lastViewed, this.completed = false});

  factory _MiniProgress.fromMap(Map<String, dynamic> map) => _MiniProgress(
        viewCount: map['viewCount'] is int
            ? map['viewCount'] as int
            : int.tryParse(map['viewCount']?.toString() ?? '') ?? 0,
        lastViewed: map['lastViewed'] != null
            ? DateTime.tryParse(map['lastViewed'].toString())
            : null,
        completed: map['completed'] == true,
      );

  Map<String, dynamic> toMap() => {
        'viewCount': viewCount,
        if (lastViewed != null) 'lastViewed': lastViewed!.toIso8601String(),
        'completed': completed,
      };
}
