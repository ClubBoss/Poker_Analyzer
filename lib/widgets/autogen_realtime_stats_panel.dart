import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/autogen_status_dashboard_service.dart';

/// Compact real-time display of autogeneration statistics.
class AutogenRealtimeStatsPanel extends StatelessWidget {
  const AutogenRealtimeStatsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AutogenStatusDashboardService.instance;
    return ChangeNotifierProvider.value(
      value: service,
      child: Consumer<AutogenStatusDashboardService>(
        builder: (context, dashboard, _) {
          final stats = dashboard.stats;
          return Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('🧠 Packs: ${stats.totalPacks}'),
                Text('🎯 Spots: ${stats.totalSpots}'),
                Text('⚠️ Skipped: ${stats.skippedSpots}'),
                Text('🔐 Fingerprints: ${stats.fingerprintCount}'),
              ],
            ),
          );
        },
      ),
    );
  }
}
