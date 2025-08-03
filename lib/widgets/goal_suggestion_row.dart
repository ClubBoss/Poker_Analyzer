import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/goal_recommendation.dart';
import '../models/user_goal.dart';
import '../services/user_goal_engine.dart';
import '../utils/snackbar_util.dart';

/// Horizontal list of goal recommendation cards.
class GoalSuggestionRow extends StatelessWidget {
  final List<GoalRecommendation> recommendations;
  const GoalSuggestionRow({super.key, required this.recommendations});

  Future<void> _addGoal(BuildContext context, GoalRecommendation rec) async {
    final engine = context.read<UserGoalEngine>();
    final now = DateTime.now();
    final isDecay = rec.type == GoalRecommendationType.decay;
    final goal = UserGoal(
      id: '${isDecay ? 'decay' : 'mistake'}_${rec.tag}_${now.millisecondsSinceEpoch}',
      title: isDecay ? 'Восстановить тег ${rec.tag}' : 'Исправить ошибку ${rec.tag}',
      type: 'tag',
      target: isDecay ? 80 : 90,
      base: 0,
      createdAt: now,
      tag: rec.tag,
      targetAccuracy: isDecay ? 80.0 : 90.0,
    );
    await engine.addGoal(goal);
    if (context.mounted) {
      SnackbarUtil.showMessage(context, 'Цель добавлена!');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    return SizedBox(
      height: 170,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: recommendations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final rec = recommendations[index];
          final isDecay = rec.type == GoalRecommendationType.decay;
          final icon = isDecay ? '🧠' : '⚠️';
          final buttonLabel =
              isDecay ? 'Восстановить навык' : 'Исправить ошибку';
          return Container(
            width: 200,
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
                    Text(icon, style: const TextStyle(fontSize: 20)),
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
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => _addGoal(context, rec),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: accent),
                    child: Text(buttonLabel),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
