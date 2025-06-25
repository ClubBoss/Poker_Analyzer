import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/streak_service.dart';
import '../services/training_stats_service.dart';
import '../services/daily_target_service.dart';
import '../theme/app_colors.dart';
import 'daily_progress_history_screen.dart';

class GoalOverviewScreen extends StatelessWidget {
  const GoalOverviewScreen({super.key});

  Color _color(int count, int target) {
    if (count >= target) return Colors.greenAccent;
    if (count > 0) return Colors.orangeAccent;
    return Colors.white24;
  }

  @override
  Widget build(BuildContext context) {
    final streakService = context.watch<StreakService>();
    final stats = context.watch<TrainingStatsService>();
    final targetService = context.watch<DailyTargetService>();
    final streak = streakService.count;
    final history = streakService.history;
    final maxStreak = history.isEmpty
        ? streak
        : history.map((e) => e.value).reduce(math.max);
    final target = targetService.target;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final days = [for (var i = 0; i < 7; i++) start.add(Duration(days: i))];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DailyProgressHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Streak: $streak',
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 4),
                Text('Max: $maxStreak',
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Target: $target',
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 7,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemBuilder: (context, i) {
                    final d = days[i];
                    final key = DateTime(d.year, d.month, d.day);
                    final count = stats.handsPerDay[key] ?? 0;
                    final color = _color(count, target);
                    return Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('${d.day}',
                          style: const TextStyle(color: Colors.white)),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () async {
                      final controller =
                          TextEditingController(text: target.toString());
                      final int? value = await showDialog<int>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: AppColors.cardBackground,
                            title: const Text('Daily Goal',
                                style: TextStyle(color: Colors.white)),
                            content: TextField(
                              controller: controller,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Hands',
                                labelStyle: TextStyle(color: Colors.white),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  final v = int.tryParse(controller.text);
                                  if (v != null && v > 0) {
                                    Navigator.pop(context, v);
                                  } else {
                                    Navigator.pop(context);
                                  }
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                      if (value != null) {
                        await targetService.setTarget(value);
                      }
                    },
                    child: const Text('Change Goal'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
