import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_pack_model.dart';

/// Tracks how often skill tags appear across generated training packs.
class SkillTagCoverageTrackerService {
  SkillTagCoverageTrackerService._();

  /// Singleton instance.
  static final SkillTagCoverageTrackerService instance =
      SkillTagCoverageTrackerService._();

  static const _prefsKey = 'skill_tag_usage_map';

  /// Logs tag usage for [pack]. Tags are normalized to lowercase and
  /// duplicates within a pack are ignored.
  Future<void> logPack(TrainingPackModel pack) async {
    final prefs = await SharedPreferences.getInstance();
    final counts = await getTagUsageCount();
    final tags = <String>{for (final t in pack.tags) _normalize(t)};
    for (final tag in tags) {
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
    await prefs.setString(_prefsKey, jsonEncode(counts));
  }

  /// Returns cumulative tag usage counts.
  Future<Map<String, int>> getTagUsageCount() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in data.entries) e.key: (e.value as num).toInt(),
      };
    } catch (_) {
      return {};
    }
  }

  /// Returns tags from [requiredTags] that have not yet been logged.
  Future<List<String>> getUncoveredTags(Set<String> requiredTags) async {
    final counts = await getTagUsageCount();
    final normalized = requiredTags.map(_normalize).toSet();
    return [
      for (final tag in normalized)
        if ((counts[tag] ?? 0) == 0) tag,
    ];
  }

  /// Clears all stored tag usage data.
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  String _normalize(String tag) => tag.trim().toLowerCase();
}
