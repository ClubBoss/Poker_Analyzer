import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/date_utils.dart';
import '../services/session_log_service.dart';

class PackHistoryScreen extends StatelessWidget {
  final String templateId;
  final String title;
  const PackHistoryScreen({
    super.key,
    required this.templateId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<SessionLogService>().filter(
      templateId: templateId,
    )..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    final sessions = logs.take(10).toList();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      backgroundColor: const Color(0xFF1B1C1E),
      body: sessions.isEmpty
          ? const Center(
              child: Text(
                'История пуста',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Colors.white24),
              itemBuilder: (context, index) {
                final s = sessions[index];
                final total = s.correctCount + s.mistakeCount;
                final acc = total == 0 ? 0.0 : s.correctCount * 100 / total;
                final success = acc >= 80;
                final duration = s.completedAt.difference(s.startedAt);
                return ListTile(
                  leading: Icon(
                    success ? Icons.check_circle : Icons.cancel,
                    color: success ? Colors.greenAccent : Colors.redAccent,
                  ),
                  title: Text(
                    formatDateTime(s.completedAt),
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${acc.toStringAsFixed(1)}% • ${formatDuration(duration)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              },
            ),
    );
  }
}
