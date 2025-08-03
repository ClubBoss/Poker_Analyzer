import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/goal_recommendation.dart';
import '../models/user_goal.dart';
import '../services/smart_decay_goal_generator.dart';
import '../services/user_goal_engine.dart';
import '../utils/snackbar_util.dart';

class SmartDecayGoalBanner extends StatefulWidget {
  const SmartDecayGoalBanner({super.key});

  @override
  State<SmartDecayGoalBanner> createState() => _SmartDecayGoalBannerState();
}

class _SmartDecayGoalBannerState extends State<SmartDecayGoalBanner> {
  bool _loading = true;
  GoalRecommendation? _rec;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final generator = SmartDecayGoalGenerator();
    final list = await generator.recommendDecayRecoveryGoals();
    if (!mounted) return;
    setState(() {
      _rec = list.isNotEmpty ? list.first : null;
      _loading = false;
    });
  }

  Future<void> _addGoal() async {
    final rec = _rec;
    if (rec == null) return;
    final now = DateTime.now();
    final goal = UserGoal(
      id: 'decay_${rec.tag}_${now.millisecondsSinceEpoch}',
      title: 'Восстановить тег ${rec.tag}',
      type: 'tag',
      target: 80,
      base: 0,
      createdAt: now,
      tag: rec.tag,
      targetAccuracy: 80.0,
    );
    await context.read<UserGoalEngine>().addGoal(goal);
    if (mounted) {
      SnackbarUtil.showMessage(context, 'Цель добавлена!');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _rec == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    final rec = _rec!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🧠', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '#${rec.tag}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            rec.reason,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _addGoal,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text('Восстановить навык'),
            ),
          ),
        ],
      ),
    );
  }
}
