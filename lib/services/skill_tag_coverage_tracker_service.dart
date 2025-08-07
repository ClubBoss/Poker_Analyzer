import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_pack_model.dart';
import '../utils/shared_prefs_keys.dart';

/// Tracks how often each skill tag appears across generated packs
/// and exposes coverage analytics.
class SkillTagCoverageTrackerService {
  static const String _key = SharedPrefsKeys.skillTagUsageCounts;

  /// Logs tag usage for [pack] and persists counts.
  Future<void> logPack(TrainingPackModel pack) async {
    final prefs = await SharedPreferences.getInstance();
    final counts = await getTagUsageCount();
    for (final spot in pack.spots) {
      for (final tag in spot.tags) {
        final norm = tag.trim().toLowerCase();
        if (norm.isEmpty) continue;
        counts[norm] = (counts[norm] ?? 0) + 1;
      }
    }
    await prefs.setString(_key, jsonEncode(counts));
  }

  /// Returns the usage count for each tracked tag.
  Future<Map<String, int>> getTagUsageCount() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <String, int>{};
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return data.map((k, v) => MapEntry(k, v as int));
  }

  /// Returns tags from [requiredTags] that have never been logged.
  Future<List<String>> getUncoveredTags(Set<String> requiredTags) async {
    final counts = await getTagUsageCount();
    final uncovered = <String>[];
    for (final tag in requiredTags) {
      final norm = tag.trim().toLowerCase();
      if ((counts[norm] ?? 0) == 0) {
        uncovered.add(tag);
      }
    }
    return uncovered;
  }
}

