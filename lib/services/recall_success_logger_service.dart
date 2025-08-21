import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/recall_success_entry.dart';
import 'decay_recall_evaluator_service.dart';

/// Logs successful recall events after decay interventions.
class RecallSuccessLoggerService {
  static const String _prefsKey = 'recall_success_log';

  final DecayRecallEvaluatorService evaluator;

  RecallSuccessLoggerService._({DecayRecallEvaluatorService? evaluator})
    : evaluator = evaluator ?? const DecayRecallEvaluatorService();

  static final RecallSuccessLoggerService instance =
      RecallSuccessLoggerService._();

  final List<RecallSuccessEntry> _logs = [];
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
              (e) => RecallSuccessEntry.fromJson(Map<String, dynamic>.from(e)),
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

  /// Evaluates and logs a successful recall for [tag] if criteria met.
  Future<void> logSuccess(String tag, {String? source}) async {
    final key = tag.trim().toLowerCase();
    if (key.isEmpty) return;
    final success = await evaluator.wasRecallSuccessful(key);
    if (!success) return;
    await _load();
    _logs.insert(
      0,
      RecallSuccessEntry(tag: key, timestamp: DateTime.now(), source: source),
    );
    if (_logs.length > 100) {
      _logs.removeRange(100, _logs.length);
    }
    await _save();
  }

  /// Returns logged success events, optionally filtered by [tag]. Most recent first.
  Future<List<RecallSuccessEntry>> getSuccesses({String? tag}) async {
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
