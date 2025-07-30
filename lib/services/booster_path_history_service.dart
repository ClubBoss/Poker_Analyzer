import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/booster_tag_history.dart';

/// Stores booster tag interaction history in local preferences.
class BoosterPathHistoryService {
  BoosterPathHistoryService._();
  static final BoosterPathHistoryService instance = BoosterPathHistoryService._();

  static const String _prefix = 'booster_tag_history_';

  Future<BoosterTagHistory?> _loadTag(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$tag';
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is Map<String, dynamic>) {
        return BoosterTagHistory.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _saveTag(String tag, BoosterTagHistory hist) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$tag';
    await prefs.setString(key, jsonEncode(hist.toJson()));
  }

  Future<void> _update(String tag, {bool shown = false, bool started = false, bool completed = false}) async {
    tag = tag.trim().toLowerCase();
    if (tag.isEmpty) return;
    final existing = await _loadTag(tag);
    final now = DateTime.now();
    final updated = (existing ?? BoosterTagHistory(tag: tag, shownCount: 0, startedCount: 0, completedCount: 0, lastInteraction: now)).copyWith(
      shownCount: (existing?.shownCount ?? 0) + (shown ? 1 : 0),
      startedCount: (existing?.startedCount ?? 0) + (started ? 1 : 0),
      completedCount: (existing?.completedCount ?? 0) + (completed ? 1 : 0),
      lastInteraction: now,
    );
    await _saveTag(tag, updated);
  }

  /// Record that a booster with [tag] was shown to the user.
  Future<void> markShown(String tag) async {
    await _update(tag, shown: true);
  }

  /// Record that a booster with [tag] was started by the user.
  Future<void> markStarted(String tag) async {
    await _update(tag, started: true);
  }

  /// Record that a booster with [tag] was completed by the user.
  Future<void> markCompleted(String tag) async {
    await _update(tag, completed: true);
  }

  /// Returns aggregated history keyed by tag.
  Future<Map<String, BoosterTagHistory>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, BoosterTagHistory>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_prefix)) continue;
      final raw = prefs.getString(key);
      if (raw == null) continue;
      try {
        final data = jsonDecode(raw);
        if (data is Map<String, dynamic>) {
          final hist = BoosterTagHistory.fromJson(data);
          result[hist.tag] = hist;
        }
      } catch (_) {}
    }
    return result;
  }
}
