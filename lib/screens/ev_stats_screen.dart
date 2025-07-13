import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/ev_stats_chart.dart';
import '../widgets/sync_status_widget.dart';
import '../services/saved_hand_manager_service.dart';

class EvStatsScreen extends StatelessWidget {
  static const route = '/ev_stats';
  const EvStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<SavedHandManagerService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика EV'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [EvStatsChart()],
      ),
    );
  }
}
