import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Tracks view and completion stats for theory mini lessons.
class MiniLessonProgressTracker {
  MiniLessonProgressTracker._();
  static final MiniLessonProgressTracker instance = MiniLessonProgressTracker._();

  static const String _prefix = 'mini_lesson_progress_';

  final Map<String, _MiniProgress> _cache = {};
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

