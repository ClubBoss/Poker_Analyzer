import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/daily_ev_icm_chart.dart';

import '../services/training_stats_service.dart';
import '../widgets/sync_status_widget.dart';

class EvIcmAnalyticsScreen extends StatelessWidget {
  static const route = '/ev_icm_analytics';
  const EvIcmAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<TrainingStatsService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('EV & ICM Analytics'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [DailyEvIcmChart()],
      ),
    );
  }
}
