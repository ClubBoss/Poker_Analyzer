import 'dart:developer' as developer;

import 'package:poker_analyzer/services/smart_booster_exclusion_tracker_service.dart';

class BoosterExclusionAnalytics {
  final Map<String, int> exclusionsByReason;
  final Map<String, int> exclusionsByTag;
  final Map<String, Map<String, int>> exclusionsByTagAndReason;

  BoosterExclusionAnalytics({
    required this.exclusionsByReason,
    required this.exclusionsByTag,
    required this.exclusionsByTagAndReason,
  });
}

class BoosterExclusionAnalyticsDashboardService {
  BoosterExclusionAnalyticsDashboardService();

  Future<BoosterExclusionAnalytics> getDashboardData() async {
    final log = await SmartBoosterExclusionTrackerService().exportLog();
    final Map<String, int> byReason = {};
    final Map<String, int> byTag = {};
    final Map<String, Map<String, int>> byTagAndReason = {};

    for (final entry in log) {
      final tag = (entry['tag'] ?? '') as String;
      final reason = (entry['reason'] ?? '') as String;

      byReason[reason] = (byReason[reason] ?? 0) + 1;
      byTag[tag] = (byTag[tag] ?? 0) + 1;

      final reasonMap = byTagAndReason.putIfAbsent(tag, () => {});
      reasonMap[reason] = (reasonMap[reason] ?? 0) + 1;
    }

    return BoosterExclusionAnalytics(
      exclusionsByReason: byReason,
      exclusionsByTag: byTag,
      exclusionsByTagAndReason: byTagAndReason,
    );
  }

  Future<void> printSummary() async {
    final data = await getDashboardData();
    final reasons = data.exclusionsByReason.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final tags = data.exclusionsByTag.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    developer.log('Top exclusion reasons:');
    for (int i = 0; i < reasons.length && i < 5; i++) {
      final r = reasons[i];
      developer.log('${r.key}: ${r.value}');
    }

    developer.log('Top exclusion tags:');
    for (int i = 0; i < tags.length && i < 5; i++) {
      final t = tags[i];
      developer.log('${t.key}: ${t.value}');
    }
  }
}
