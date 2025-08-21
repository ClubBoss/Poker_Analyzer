import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/recall_boost_view_entry.dart';

/// Logs interactions with auto-injected theory snippets.
class RecallBoostInteractionLogger {
  static const String _prefsKey = 'recall_boost_views';

  RecallBoostInteractionLogger._();
  static final RecallBoostInteractionLogger instance =
      RecallBoostInteractionLogger._();

  final List<RecallBoostViewEntry> _logs = [];
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is List) {
          _logs.addAll(
            data.whereType<Map>().map(
              (e) =>
                  RecallBoostViewEntry.fromJson(Map<String, dynamic>.from(e)),
            ),
          );
          _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode([for (final l in _logs) l.toJson()]),
    );
  }

  /// Logs that [tag] within [nodeId] was viewed for [durationMs].
  Future<void> logView(String tag, String nodeId, int durationMs) async {
    final t = tag.trim().toLowerCase();
    if (t.isEmpty) return;
    await _load();
    _logs.insert(
      0,
      RecallBoostViewEntry(
        tag: t,
        nodeId: nodeId,
        timestamp: DateTime.now(),
        durationMs: durationMs,
      ),
    );
    if (_logs.length > 100) _logs.removeRange(100, _logs.length);
    await _save();
  }

  /// Returns logged view entries, optionally filtered by [tag].
  Future<List<RecallBoostViewEntry>> getLogs({String? tag}) async {
    await _load();
    if (tag == null) return List.unmodifiable(_logs);
    final norm = tag.trim().toLowerCase();
    return List.unmodifiable(_logs.where((e) => e.tag == norm));
  }

  /// Resets in-memory state for testing.
  void resetForTest() {
    _loaded = false;
    _logs.clear();
  }
}
