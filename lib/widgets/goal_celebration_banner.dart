import 'package:flutter/material.dart';
import '../models/user_goal.dart';

class GoalCelebrationBanner extends StatelessWidget {
  final UserGoal goal;
  final VoidCallback onClose;
  const GoalCelebrationBanner({
    Key? key,
    required this.goal,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tag = goal.tag ?? goal.title;
    return MaterialBanner(
      leading: const Icon(Icons.emoji_events, color: Colors.amber),
      content: Text('🎉 Цель #$tag достигнута!'),
      actions: [TextButton(onPressed: onClose, child: const Text('Закрыть'))],
    );
  }
}
