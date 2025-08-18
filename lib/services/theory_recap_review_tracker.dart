import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/theory_recap_review_entry.dart';

/// Stores history of recap sessions triggered by various reminders.
class TheoryRecapReviewTracker {
  TheoryRecapReviewTracker._();
  static final TheoryRecapReviewTracker instance = TheoryRecapReviewTracker._();

  static const _key = 'theory_recap_review_history';

  final List<TheoryRecapReviewEntry> _history = [];
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
              (e) =>
                  TheoryRecapReviewEntry.fromJson(Map<String, dynamic>.from(e)),
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

  /// Logs a recap review entry.
  Future<void> log(TheoryRecapReviewEntry entry) async {
    await _load();
    _history.insert(0, entry);
    if (_history.length > 100) _history.removeRange(100, _history.length);
    await _save();
  }

  /// Returns stored history, filtered by [trigger] if provided.
  Future<List<TheoryRecapReviewEntry>> getHistory({String? trigger}) async {
    await _load();
    final list = trigger == null
        ? _history
        : _history.where((e) => e.trigger == trigger);
    return List<TheoryRecapReviewEntry>.unmodifiable(list);
  }
}
