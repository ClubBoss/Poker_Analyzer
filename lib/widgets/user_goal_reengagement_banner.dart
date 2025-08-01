import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_goal.dart';
import '../services/goal_analytics_service.dart';
import '../services/user_goal_engine.dart';
import '../screens/training_home_screen.dart';

/// Banner reminding the user to resume the stalest active goal.
class GoalReengagementBanner extends StatefulWidget {
  const GoalReengagementBanner({super.key});

  @override
  State<GoalReengagementBanner> createState() => _GoalReengagementBannerState();
}

class _GoalReengagementBannerState extends State<GoalReengagementBanner> {
  static const Duration _stale = Duration(days: 3);

  bool _loading = true;
  UserGoal? _goal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final engine = context.read<UserGoalEngine>();
    final history = await GoalAnalyticsService.instance.getGoalHistory();
    final Map<String, DateTime> lastUpdate = {};
    for (final e in history) {
      final id = e['goalId'] as String?;
      if (id == null) continue;
      final tsStr = e['timestamp'] as String? ?? e['time'] as String?;
      final ts = tsStr != null ? DateTime.tryParse(tsStr) : null;
      if (ts == null) continue;
      final prev = lastUpdate[id];
      if (prev == null || ts.isAfter(prev)) {
        lastUpdate[id] = ts;
      }
    }
    final now = DateTime.now();
    UserGoal? stale;
    DateTime oldest = now;
    for (final g in engine.goals) {
      if (g.completed) continue;
      final last = lastUpdate[g.id] ?? g.createdAt;
      if (now.difference(last) <= _stale) continue;
      if (last.isBefore(oldest)) {
        oldest = last;
        stale = g;
      }
    }
    if (mounted) {
      setState(() {
        _goal = stale;
        _loading = false;
      });
    }
  }

  Future<void> _resume() async {
    if (_goal == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingHomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _goal == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    final tag = _goal!.tag ?? _goal!.title;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text('🕒', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Продолжите цель: #$tag',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _resume,
            style: ElevatedButton.styleFrom(backgroundColor: accent),
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }
}
