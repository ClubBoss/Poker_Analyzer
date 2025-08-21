import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_action_logger.dart';

/// Tracks inbox booster banner interactions for engagement analytics.
class InboxBoosterTrackerService {
  InboxBoosterTrackerService._();
  static final InboxBoosterTrackerService instance =
      InboxBoosterTrackerService._();

  static const _prefsKey = 'inbox_booster_interactions';
  static const _queueKey = 'inbox_booster_queue';

  final Map<String, _BoosterStats> _cache = {};
  bool _loaded = false;
  List<String> _queue = [];
  bool _queueLoaded = false;

  /// Clears cache for testing purposes.
  void resetForTest() {
    _loaded = false;
    _cache.clear();
  }

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is Map) {
          data.forEach((key, value) {
            if (value is Map) {
              _cache[key.toString()] = _BoosterStats.fromJson(
                Map<String, dynamic>.from(value),
              );
            }
          });
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({for (final e in _cache.entries) e.key: e.value.toJson()}),
    );
  }

  Future<void> _loadQueue() async {
    if (_queueLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    _queue = prefs.getStringList(_queueKey) ?? [];
    _queueLoaded = true;
  }

  Future<void> _saveQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_queueKey, _queue);
  }

  /// Marks [lessonId] as shown now.
  Future<void> markShown(String lessonId) async {
    await _load();
    await _loadQueue();
    final stats = _cache[lessonId] ?? const _BoosterStats();
    final updated = stats.copyWith(
      shows: stats.shows + 1,
      lastShown: DateTime.now(),
    );
    _cache[lessonId] = updated;
    await _save();
    if (!_queue.contains(lessonId)) {
      _queue.add(lessonId);
      await _saveQueue();
    }
    await UserActionLogger.instance.logEvent({
      'event': 'inbox_booster.shown',
      'lesson': lessonId,
    });
  }

  /// Marks [lessonId] as clicked now.
  Future<void> markClicked(String lessonId) async {
    await _load();
    await _loadQueue();
    final stats = _cache[lessonId] ?? const _BoosterStats();
    final updated = stats.copyWith(
      clicks: stats.clicks + 1,
      lastClicked: DateTime.now(),
    );
    _cache[lessonId] = updated;
    await _save();
    _queue.remove(lessonId);
    await _saveQueue();
    await UserActionLogger.instance.logEvent({
      'event': 'inbox_booster.clicked',
      'lesson': lessonId,
    });
  }

  /// Adds [lessonId] to the inbox queue if not already present.
  Future<void> addToInbox(String lessonId) async {
    await _loadQueue();
    if (!_queue.contains(lessonId)) {
      _queue.add(lessonId);
      await _saveQueue();
    }
  }

  /// Returns current inbox booster lesson ids.
  Future<List<String>> getInbox() async {
    await _loadQueue();
    return List.unmodifiable(_queue);
  }

  /// Clears all queued inbox boosters.
  Future<void> clearInbox() async {
    await _loadQueue();
    if (_queue.isNotEmpty) {
      _queue.clear();
      await _saveQueue();
    }
  }

  /// Removes [lessonId] from the inbox queue.
  Future<void> removeFromInbox(String lessonId) async {
    await _loadQueue();
    if (_queue.remove(lessonId)) {
      await _saveQueue();
    }
  }

  /// Whether [lessonId] was shown within [window].
  Future<bool> wasRecentlyShown(
    String lessonId, {
    Duration window = const Duration(days: 1),
  }) async {
    await _load();
    final stats = _cache[lessonId];
    final ts = stats?.lastShown;
    if (ts == null) return false;
    return DateTime.now().difference(ts) < window;
  }

  /// Returns raw interaction data keyed by lesson id.
  Future<Map<String, Map<String, dynamic>>> getInteractionStats() async {
    await _load();
    return {for (final e in _cache.entries) e.key: e.value.toJson()};
  }
}

class _BoosterStats {
  final int shows;
  final int clicks;
  final DateTime? lastShown;
  final DateTime? lastClicked;

  const _BoosterStats({
    this.shows = 0,
    this.clicks = 0,
    this.lastShown,
    this.lastClicked,
  });

  _BoosterStats copyWith({
    int? shows,
    int? clicks,
    DateTime? lastShown,
    DateTime? lastClicked,
  }) {
    return _BoosterStats(
      shows: shows ?? this.shows,
      clicks: clicks ?? this.clicks,
      lastShown: lastShown ?? this.lastShown,
      lastClicked: lastClicked ?? this.lastClicked,
    );
  }

  Map<String, dynamic> toJson() => {
        'shows': shows,
        'clicks': clicks,
        if (lastShown != null) 'lastShown': lastShown!.toIso8601String(),
        if (lastClicked != null) 'lastClicked': lastClicked!.toIso8601String(),
      };

  factory _BoosterStats.fromJson(Map<String, dynamic> json) => _BoosterStats(
        shows: (json['shows'] as num?)?.toInt() ?? 0,
        clicks: (json['clicks'] as num?)?.toInt() ?? 0,
        lastShown: DateTime.tryParse(json['lastShown'] as String? ?? ''),
        lastClicked: DateTime.tryParse(json['lastClicked'] as String? ?? ''),
      );
}
