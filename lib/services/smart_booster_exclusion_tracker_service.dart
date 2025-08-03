import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/shared_prefs_keys.dart';

/// Logs boosters that are excluded from the inbox for diagnostics.
class SmartBoosterExclusionTrackerService {
  SmartBoosterExclusionTrackerService();

  static const int _maxEntries = 100;

  /// Records that a booster with [tag] was skipped for [reason].
  Future<void> logExclusion(String tag, String reason) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = prefs.getStringList(SharedPrefsKeys.boosterExclusionLog) ?? [];
    entries.add(jsonEncode({
      'tag': tag,
      'reason': reason,
      'timestamp': DateTime.now().toIso8601String(),
    }));
    if (entries.length > _maxEntries) {
      entries.removeRange(0, entries.length - _maxEntries);
    }
    await prefs.setStringList(SharedPrefsKeys.boosterExclusionLog, entries);
  }

  /// Returns the raw exclusion log entries for diagnostics.
  Future<List<Map<String, dynamic>>> exportLog() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = prefs.getStringList(SharedPrefsKeys.boosterExclusionLog) ?? [];
    return entries
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
  }

  /// Clears the stored exclusion log.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(SharedPrefsKeys.boosterExclusionLog);
  }
}

