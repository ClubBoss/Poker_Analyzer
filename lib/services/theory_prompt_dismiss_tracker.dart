import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/theory_prompt_dismiss_entry.dart';

/// Tracks dismissed theory recap or booster prompts to reduce annoyance.
class TheoryPromptDismissTracker {
  TheoryPromptDismissTracker._();
  static final TheoryPromptDismissTracker instance =
      TheoryPromptDismissTracker._();

  static const _key = 'theory_prompt_dismiss_history';

  final List<TheoryPromptDismissEntry> _history = [];
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is List) {
          _history.addAll(
            data.whereType<Map>().map(
                  (e) => TheoryPromptDismissEntry.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                ),
          );
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final h in _history) h.toJson()]),
    );
  }

  /// Marks [lessonId] as dismissed so it won't be suggested again within the
  /// cooldown period.
  Future<void> markDismissed(
    String lessonId, {
    String trigger = '',
    DateTime? timestamp,
  }) async {
    await _load();
    _history.insert(
      0,
      TheoryPromptDismissEntry(
        lessonId: lessonId,
        trigger: trigger,
        timestamp: timestamp ?? DateTime.now(),
      ),
    );
    if (_history.length > 50) {
      _history.removeRange(50, _history.length);
    }
    await _save();
  }

  /// Deprecated: use [markDismissed] instead.
  @Deprecated('Use markDismissed')
  Future<void> logDismiss(String lessonId, String trigger) =>
      markDismissed(lessonId, trigger: trigger);

  /// Returns true if [lessonId] was dismissed within [cooldown].
  Future<bool> isRecentlyDismissed(
    String lessonId, {
    Duration cooldown = const Duration(hours: 12),
  }) async {
    await _load();
    for (final e in _history) {
      if (e.lessonId == lessonId &&
          DateTime.now().difference(e.timestamp) < cooldown) {
        return true;
      }
    }
    return false;
  }

  /// Returns dismissal history optionally filtered by [before]. Most recent
  /// first.
  Future<List<TheoryPromptDismissEntry>> getHistory({DateTime? before}) async {
    await _load();
    Iterable<TheoryPromptDismissEntry> list = _history;
    if (before != null) {
      list = list.where((e) => e.timestamp.isBefore(before));
    }
    return List<TheoryPromptDismissEntry>.unmodifiable(list);
  }

  /// Clears cached data for testing purposes.
  void resetForTest() {
    _loaded = false;
    _history.clear();
  }
}
