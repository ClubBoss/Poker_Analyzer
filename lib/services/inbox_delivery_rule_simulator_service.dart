import 'dart:developer' as developer;

import 'smart_booster_exclusion_tracker_service.dart';
import 'smart_booster_inbox_limiter_service.dart';
import 'smart_inbox_heuristic_tuning_service.dart';

class InboxSimulationResult {
  final String tag;
  final bool wouldShow;
  final String reasonIfExcluded;

  const InboxSimulationResult({
    required this.tag,
    required this.wouldShow,
    required this.reasonIfExcluded,
  });
}

/// Simulates Smart Inbox delivery decisions for debugging and tuning.
class InboxDeliveryRuleSimulatorService {
  InboxDeliveryRuleSimulatorService({
    SmartInboxHeuristicTuningService? tuning,
    SmartBoosterExclusionTrackerService? tracker,
  })  : tuning = tuning ?? SmartInboxHeuristicTuningService(),
        tracker = tracker ?? SmartBoosterExclusionTrackerService();

  final SmartInboxHeuristicTuningService tuning;
  final SmartBoosterExclusionTrackerService tracker;

  /// Simulates whether each [tags] would be shown given current heuristics
  /// and exclusion history.
  Future<List<InboxSimulationResult>> simulate(List<String> tags) async {
    await tuning.tuneHeuristics();
    final log = await tracker.exportLog();
    final now = DateTime.now();

    final results = <InboxSimulationResult>[];
    for (final tag in tags) {
      final cooldown = tuning.cooldownOverrides[tag] ??
          SmartBoosterInboxLimiterService.tagCooldown;
      final dailyLimit = SmartBoosterInboxLimiterService.maxPerDay +
          (tuning.dailyLimitAdjustments[tag] ?? 0);

      DateTime? lastRateLimited;
      var rateLimitedCount = 0;
      for (final entry in log) {
        if (entry['tag'] != tag) continue;
        final reason = entry['reason'] as String? ?? '';
        if (reason != 'rateLimited') continue;
        final tsStr = entry['timestamp'] as String?;
        if (tsStr == null) continue;
        final ts = DateTime.tryParse(tsStr);
        if (ts == null) continue;
        if (lastRateLimited == null || ts.isAfter(lastRateLimited)) {
          lastRateLimited = ts;
        }
        if (now.difference(ts) < const Duration(hours: 24)) {
          rateLimitedCount++;
        }
      }

      var wouldShow = true;
      var reason = '';
      if (lastRateLimited != null &&
          now.difference(lastRateLimited) < cooldown) {
        wouldShow = false;
        reason = 'cooldown';
      } else if (rateLimitedCount >= dailyLimit) {
        wouldShow = false;
        reason = 'rateLimited';
      }

      results.add(
        InboxSimulationResult(
          tag: tag,
          wouldShow: wouldShow,
          reasonIfExcluded: reason,
        ),
      );
    }
    return results;
  }

  /// Prints a simple report for [results] to the console.
  void printSimulationReport(List<InboxSimulationResult> results) {
    for (final r in results) {
      final status = r.wouldShow ? 'SHOW' : 'EXCLUDED (${r.reasonIfExcluded})';
      developer.log('${r.tag}: $status');
    }
  }
}
