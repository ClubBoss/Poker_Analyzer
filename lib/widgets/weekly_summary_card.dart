import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/session_log_service.dart';
import '../services/tag_mastery_service.dart';
import '../screens/training_stats_screen.dart';

class WeeklySummaryCard extends StatelessWidget {
  const WeeklySummaryCard({super.key});

  bool get _show => DateTime.now().weekday == DateTime.sunday;

  String _capitalize(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;

  Future<_SummaryData?> _load(BuildContext context) async {
    final logsService = context.read<SessionLogService>();
    await logsService.load();
    final mastery = context.read<TagMasteryService>();

    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final weekLogs = logsService.filter(
      range: DateTimeRange(start: start, end: now),
    );
    int hands = 0;
    int correct = 0;
    for (final log in weekLogs) {
      hands += log.correctCount + log.mistakeCount;
      correct += log.correctCount;
    }
    final acc = hands > 0 ? correct * 100 / hands : 0.0;

    final delta = await mastery.computeDelta(fromLastWeek: true);
    final improved = delta.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = improved.take(3).toList();

    return _SummaryData(hands, acc, top);
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();
    return FutureBuilder<_SummaryData?>(
      future: _load(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final data = snapshot.data!;
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TrainingStatsScreen()),
            );
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.amberAccent),
                    SizedBox(width: 8),
                    Text(
                      'Weekly Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${data.hands} hands trained',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  '${data.accuracy.toStringAsFixed(1)}% accuracy',
                  style: const TextStyle(color: Colors.white70),
                ),
                if (data.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Improved Tags',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  for (final e in data.tags)
                    Text(
                      '${_capitalize(e.key)} +${(e.value * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'View full analytics',
                    style: TextStyle(color: Colors.blueAccent),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryData {
  final int hands;
  final double accuracy;
  final List<MapEntry<String, double>> tags;
  const _SummaryData(this.hands, this.accuracy, this.tags);
}
