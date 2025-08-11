import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/autogen_stats_dashboard_service.dart';

/// Compact real-time display of autogeneration statistics.
class AutogenRealtimeStatsPanel extends StatelessWidget {
  const AutogenRealtimeStatsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AutogenStatsDashboardService.instance;
    return ChangeNotifierProvider.value(
      value: service,
      child: Consumer<AutogenStatsDashboardService>(
        builder: (context, dashboard, _) {
          final stats = dashboard.stats;
          return Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text('🧠 Packs: ${stats.totalPacks}'),
                    Text('🎯 Spots: ${stats.totalSpots}'),
                    Text('⚠️ Skipped: ${stats.skippedSpots}'),
                    Text('🔐 Fingerprints: ${stats.fingerprintCount}'),
                  ],
                ),
                if (dashboard.targetTextureMix.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final entry in dashboard.targetTextureMix.entries)
                          Text(
                            '${entry.key}: '
                            '${(dashboard.textureCounts[entry.key] ?? 0)}'
                            '/${(entry.value * 100).toStringAsFixed(0)}%',
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
