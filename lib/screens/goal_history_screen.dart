import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/goals_service.dart';
import '../widgets/sync_status_widget.dart';

class GoalHistoryScreen extends StatelessWidget {
  final int index;
  const GoalHistoryScreen({super.key, required this.index});

  String _format(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final mon = d.month.toString().padLeft(2, '0');
    return '$day.$mon.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<GoalsService>();
    final goal = service.goals[index];
    final history = service.historyFor(index);
    return Scaffold(
      appBar: AppBar(
        title: Text(goal.title),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: history.isEmpty
          ? const Center(child: Text('Нет данных'))
          : ListView.separated(
              itemCount: history.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                final entry = history[i];
                return ListTile(
                  title: Text(
                    _format(entry.date),
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: Text(
                    '${entry.progress}/${goal.target}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              },
            ),
    );
  }
}
