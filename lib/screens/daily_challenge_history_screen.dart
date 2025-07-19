import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/daily_challenge_history_service.dart';
import '../services/daily_challenge_streak_service.dart';

/// Displays a simple history of Daily Challenge completions.
class DailyChallengeHistoryScreen extends StatefulWidget {
  const DailyChallengeHistoryScreen({super.key});

  @override
  State<DailyChallengeHistoryScreen> createState() =>
      _DailyChallengeHistoryScreenState();
}

class _DailyChallengeHistoryScreenState
    extends State<DailyChallengeHistoryScreen> {
  late Future<Set<DateTime>> _historyFuture;
  late Future<int> _streakFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = DailyChallengeHistoryService.instance.loadHistorySet();
    _streakFuture = DailyChallengeStreakService.instance.getCurrentStreak();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История челленджей'),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF121212),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([_historyFuture, _streakFuture]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final history = snapshot.data![0] as Set<DateTime>;
          final streak = snapshot.data![1] as int? ?? 0;
          final now = DateTime.now();
          final start = DateTime(now.year, now.month, now.day)
              .subtract(const Duration(days: 13));
          final days = [
            for (int i = 0; i < 14; i++) start.add(Duration(days: i))
          ];
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            scrollDirection: Axis.horizontal,
            children: [
              const SizedBox(width: 16),
              for (final d in days) _buildDay(d, history, streak, now),
              const SizedBox(width: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDay(
      DateTime day, Set<DateTime> history, int streak, DateTime now) {
    final key = DateTime(day.year, day.month, day.day);
    final completed = history.contains(key);
    final diff = now.difference(key).inDays;
    final inStreak = completed && diff < streak;
    final dateText = DateFormat('dd.MM').format(day);
    final color = completed ? Colors.greenAccent : Colors.grey;

    return Container(
      width: 60,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: inStreak ? Colors.deepOrange : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(dateText,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
          const SizedBox(height: 8),
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: color,
            size: 20,
          ),
          if (inStreak) ...[
            const SizedBox(height: 4),
            const Icon(Icons.local_fire_department,
                color: Colors.deepOrange, size: 16),
          ]
        ],
      ),
    );
  }
}
