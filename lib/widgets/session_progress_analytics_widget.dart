import 'package:flutter/material.dart';

import '../services/training_session_completion_stats_service.dart';

class SessionProgressAnalyticsWidget extends StatefulWidget {
  const SessionProgressAnalyticsWidget({super.key});

  @override
  State<SessionProgressAnalyticsWidget> createState() =>
      _SessionProgressAnalyticsWidgetState();
}

class _SessionProgressAnalyticsWidgetState
    extends State<SessionProgressAnalyticsWidget> {
  CompletionStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = TrainingSessionCompletionStatsService();
    final stats = await service.computeStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _loading = false;
      });
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60);
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = _stats;
    if (stats == null || stats.totalSessions == 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('No sessions yet'),
        ),
      );
    }

    final accPct = (stats.averageAccuracy * 100).toStringAsFixed(1);
    final avgDuration = stats.averageDuration != null
        ? _formatDuration(stats.averageDuration!)
        : '-';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Sessions: ${stats.totalSessions}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Average Accuracy: $accPct%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Average Duration: $avgDuration',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

