import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/date_utils.dart';
import '../services/session_log_service.dart';

class StageSessionHistoryScreen extends StatelessWidget {
  final String stageId;
  const StageSessionHistoryScreen({super.key, required this.stageId});

  @override
  Widget build(BuildContext context) {
    final logs = context
        .watch<SessionLogService>()
        .logs
        .where((l) => l.templateId == stageId)
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return Scaffold(
      appBar: AppBar(title: const Text('Session History')),
      backgroundColor: const Color(0xFF1B1C1E),
      body: logs.isEmpty
          ? const Center(
              child: Text(
                'No sessions',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                final total = log.correctCount + log.mistakeCount;
                final acc = total == 0 ? 0.0 : log.correctCount / total * 100;
                final cats = log.categories.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final tagText =
                    cats.isEmpty ? null : cats.map((e) => e.key).take(3).join(', ');
                return Card(
                  color: const Color(0xFF2A2B2D),
                  child: ListTile(
                    title: Text(
                      formatDate(log.completedAt),
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Acc ${acc.toStringAsFixed(1)}% · $total рук · EV 0%',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        if (tagText != null)
                          Text(
                            tagText,
                            style: const TextStyle(color: Colors.white70),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
