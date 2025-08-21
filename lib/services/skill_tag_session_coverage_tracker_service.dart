import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'training_session_fingerprint_logger_service.dart';

/// Tracks how often skill tags appear across training sessions.
class SkillTagSessionCoverageTrackerService {
  final TrainingSessionFingerprintLoggerService logger;

  SkillTagSessionCoverageTrackerService({
    TrainingSessionFingerprintLoggerService? logger,
    SharedPreferences? prefs,
  })  : logger = logger ?? TrainingSessionFingerprintLoggerService(),
        _prefs = prefs;

  SharedPreferences? _prefs;
  static const _coverageKey = 'skill_tag_coverage_map';

  Future<SharedPreferences> get _sp async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Retrieves the persisted coverage map.
  Future<Map<String, int>> getCoverageMap() async {
    final prefs = await _sp;
    final raw = prefs.getString(_coverageKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final entry in data.entries)
          entry.key: (entry.value as num).toInt(),
      };
    } catch (_) {
      return {};
    }
  }

  /// Updates and persists the coverage map using logged sessions.
  Future<void> updateCoverageMap() async {
    final coverage = await computeCoverage();
    final prefs = await _sp;
    await prefs.setString(_coverageKey, jsonEncode(coverage));
    debugPrint('Skill tag coverage updated: $coverage');
  }

  /// Removes the stored coverage map.
  Future<void> clearCoverageMap() async {
    final prefs = await _sp;
    await prefs.remove(_coverageKey);
  }

  /// Computes how frequently each tag appears in [sessions].
  ///
  /// If [sessions] is omitted, all logged sessions will be used.
  Future<Map<String, int>> computeCoverage([
    List<TrainingSessionFingerprint>? sessions,
  ]) async {
    final list = sessions ?? await logger.getAllSessions();
    final freq = <String, int>{};
    for (final s in list) {
      for (final tag in s.tagsCovered) {
        freq.update(tag, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    return freq;
  }

  /// Returns tags occurring less than [threshold] times.
  Future<List<String>> lowFrequencyTags(
    int threshold, [
    List<TrainingSessionFingerprint>? sessions,
  ]) async {
    final coverage = await computeCoverage(sessions);
    return [
      for (final entry in coverage.entries)
        if (entry.value < threshold) entry.key,
    ];
  }
}
