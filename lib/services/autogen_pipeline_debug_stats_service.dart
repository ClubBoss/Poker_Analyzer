import 'package:flutter/foundation.dart';

/// Stats for the autogen pipeline debug panel.
class AutogenPipelineStats {
  final int generated;
  final int deduplicated;
  final int curated;
  final int published;

  const AutogenPipelineStats({
    required this.generated,
    required this.deduplicated,
    required this.curated,
    required this.published,
  });
}

/// Service providing stats for the autogen pipeline.
class AutogenPipelineDebugStatsService {
  AutogenPipelineDebugStatsService._();

  /// Returns current pipeline stats.
  static Future<AutogenPipelineStats> getStats() async {
    // In the future, retrieve real metrics from the pipeline.
    return const AutogenPipelineStats(
      generated: 0,
      deduplicated: 0,
      curated: 0,
      published: 0,
    );
  }
}
