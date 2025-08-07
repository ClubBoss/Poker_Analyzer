import 'package:flutter/material.dart';

import '../services/autogen_pipeline_debug_stats_service.dart';
import 'autogen_pipeline_status_badge_widget.dart';

/// Inline panel showing autogen pipeline status and key metrics.
class InlineAutogenDebugPanelWidget extends StatelessWidget {
  const InlineAutogenDebugPanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const AutogenPipelineStatusBadgeWidget(),
        const SizedBox(height: 8),
        ValueListenableBuilder<AutogenPipelineStats>(
          valueListenable:
              AutogenPipelineDebugStatsService.getLiveStats(),
          builder: (context, stats, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generated: ${stats.generated}  |  Deduped: ${stats.deduplicated}',
                ),
                Text(
                  'Curated: ${stats.curated}  |  Published: ${stats.published}',
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
