import 'booster_exclusion_analytics_dashboard_service.dart';

/// Dynamically tunes Smart Inbox delivery heuristics based on exclusion analytics.
class SmartInboxHeuristicTuningService {
  SmartInboxHeuristicTuningService({
    BoosterExclusionAnalyticsDashboardService? analytics,
  }) : analytics =
            analytics ?? const BoosterExclusionAnalyticsDashboardService();

  final BoosterExclusionAnalyticsDashboardService analytics;

  /// Tag specific cooldown overrides derived from analytics.
  final Map<String, Duration> cooldownOverrides = {};

  /// Tag specific priority adjustments (negative lowers priority).
  final Map<String, double> priorityAdjustments = {};

  /// Tag specific daily limit increments.
  final Map<String, int> dailyLimitAdjustments = {};

  /// Fetches exclusion analytics and adjusts heuristics in memory.
  Future<void> tuneHeuristics() async {
    final data = await analytics.getDashboardData();

    // Overused tags: many exclusions in general.
    const overuseThreshold = 5;
    // Consider a tag underused if deduplicated often or rate limited.
    const reasonThreshold = 3;

    for (final entry in data.exclusionsByTag.entries) {
      final tag = entry.key;
      final total = entry.value;
      final reasons = data.exclusionsByTagAndReason[tag] ?? {};

      if (total > overuseThreshold) {
        cooldownOverrides[tag] = const Duration(hours: 12);
        // ignore: avoid_print
        print(
            'SmartInboxHeuristicTuningService: increased cooldown for $tag due to $total exclusions');
      }

      final dedup = reasons['deduplicated'] ?? 0;
      if (dedup > reasonThreshold) {
        priorityAdjustments[tag] =
            (priorityAdjustments[tag] ?? 0) - 0.5; // lower priority
        // ignore: avoid_print
        print(
            'SmartInboxHeuristicTuningService: lowered priority for $tag due to $dedup deduplications');
      }

      final rateLimited = reasons['rateLimited'] ?? 0;
      if (rateLimited > reasonThreshold) {
        dailyLimitAdjustments[tag] = (dailyLimitAdjustments[tag] ?? 0) + 1;
        // ignore: avoid_print
        print(
            'SmartInboxHeuristicTuningService: increased daily limit for $tag due to $rateLimited rate limits');
      }
    }

    // Global reason monitoring.
    const globalThreshold = 10;
    final dedupTotal = data.exclusionsByReason['deduplicated'] ?? 0;
    if (dedupTotal > globalThreshold) {
      // ignore: avoid_print
      print(
          'SmartInboxHeuristicTuningService: high global deduplicated count ($dedupTotal), consider relaxing dedupe rules');
    }
    final rateLimitTotal = data.exclusionsByReason['rateLimited'] ?? 0;
    if (rateLimitTotal > globalThreshold) {
      // ignore: avoid_print
      print(
          'SmartInboxHeuristicTuningService: high global rateLimited count ($rateLimitTotal), consider adjusting rate limits');
    }
  }
}

