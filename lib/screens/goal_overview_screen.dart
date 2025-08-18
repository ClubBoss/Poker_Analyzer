import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/streak_service.dart';
import '../services/training_stats_service.dart';
import '../services/daily_target_service.dart';
import '../services/xp_tracker_service.dart';
import '../services/daily_tip_service.dart';
import '../services/weekly_challenge_service.dart';
import '../theme/app_colors.dart';
import 'daily_progress_history_screen.dart';
import 'achievements_screen.dart';
import '../widgets/sync_status_widget.dart';
import '../utils/responsive.dart';

class GoalOverviewScreen extends StatefulWidget {
  const GoalOverviewScreen({super.key});

  @override
  State<GoalOverviewScreen> createState() => _GoalOverviewScreenState();
}

class _GoalOverviewScreenState extends State<GoalOverviewScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DailyTipService>().ensureTodayTip();
  }

  Color _color(int count, int target) {
    if (count >= target) return Colors.greenAccent;
    if (count > 0) return AppColors.accent;
    return Colors.white24;
  }

  @override
  Widget build(BuildContext context) {
    final streakService = context.watch<StreakService>();
    final stats = context.watch<TrainingStatsService>();
    final targetService = context.watch<DailyTargetService>();
    final xpService = context.watch<XPTrackerService>();
    final challengeService = context.watch<WeeklyChallengeService>();
    final tipService = context.watch<DailyTipService>();
    final tip = tipService.tip;
    final category = tipService.category;
    final categories = tipService.categories;
    final streak = streakService.count;
    final history = streakService.history;
    final maxStreak = history.isEmpty
        ? streak
        : history.map((e) => e.value).reduce(math.max);
    final target = targetService.target;
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final days = [for (var i = 0; i < 7; i++) start.add(Duration(days: i))];
    final challenge = challengeService.current;
    final challengeProgress = challengeService.progressValue;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal'),
        centerTitle: true,
        actions: [
          SyncStatusIcon.of(context),
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
          IconButton(
            icon: const Icon(Icons.emoji_events),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AchievementsScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (tip.isNotEmpty)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Container(
                key: ValueKey('$category$tip'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.greenAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Tip of the Day',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              DropdownButton<String>(
                                value: category,
                                dropdownColor: const Color(0xFF2A2B2E),
                                underline: const SizedBox(),
                                onChanged: (v) => context
                                    .read<DailyTipService>()
                                    .setCategory(v!),
                                items: categories
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tip,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (tip.isNotEmpty) const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Streak: $streak',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Max: $maxStreak',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level ${xpService.level}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      '${xpService.xp}/${xpService.nextLevelXp} XP',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: xpService.progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.blueAccent,
                    ),
                    minHeight: 6,
                  ),
                ),
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
                Text(
                  challenge.title,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: challengeService.progress,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.greenAccent,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$challengeProgress/${challenge.target}',
                  style: const TextStyle(color: Colors.white70),
                ),
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
                Text(
                  'Daily Target: $target',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                if (streak >= 7)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accent, Colors.redAccent],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '🔥 Streak Bonus!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 7,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isCompactWidth(context) ? 4 : 7,
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
                      child: Text(
                        '${d.day}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () async {
                      final controller = TextEditingController(
                        text: target.toString(),
                      );
                      final int? value = await showDialog<int>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: AppColors.cardBackground,
                            title: const Text(
                              'Daily Goal',
                              style: TextStyle(color: Colors.white),
                            ),
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
