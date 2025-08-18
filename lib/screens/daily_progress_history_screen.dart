import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/training_stats_service.dart';
import '../services/daily_target_service.dart';
import '../widgets/sync_status_widget.dart';
import '../utils/responsive.dart';

class DailyProgressHistoryScreen extends StatelessWidget {
  const DailyProgressHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<TrainingStatsService>();
    final target = context.watch<DailyTargetService>().target;
    final map = stats.handsPerDay;
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 29));
    final days = [for (var i = 0; i < 30; i++) start.add(Duration(days: i))];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Progress'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: days.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isLandscape(context)
              ? (isCompactWidth(context) ? 6 : 10)
              : (isCompactWidth(context) ? 4 : 7),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemBuilder: (context, index) {
          final d = days[index];
          final count = map[d] ?? 0;
          final met = count >= target;
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: met ? Colors.greenAccent : Colors.redAccent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${d.day}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Text(
                  '$count',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
