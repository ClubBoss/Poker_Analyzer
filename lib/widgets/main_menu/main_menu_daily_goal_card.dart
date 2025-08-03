import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/goals_service.dart';
import '../../utils/responsive.dart';
import '../../screens/goals_overview_screen.dart';

class MainMenuDailyGoalCard extends StatelessWidget {
  const MainMenuDailyGoalCard({super.key});

  @override
  Widget build(BuildContext context) {
    final goal = context.watch<GoalsService>().dailyGoal;
    if (goal == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    final completed = goal.progress >= goal.target;
    final progress = (goal.progress / goal.target).clamp(0.0, 1.0);

    Widget buildActive() {
      return Column(
        key: const ValueKey('activeGoal'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Цель дня',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(goal.title),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                  minHeight: 6,
                ),
              ),
              const SizedBox(width: 8),
              Text('${goal.progress}/${goal.target}')
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const GoalsOverviewScreen()),
                );
              },
              child: const Text('Перейти'),
            ),
          ),
        ],
      );
    }

    Widget buildCompleted() {
      return Row(
        key: const ValueKey('completedGoal'),
        children: [
          const Icon(Icons.emoji_events, color: Colors.white),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Выполнено!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GoalsOverviewScreen()),
              );
            },
            child: const Text('Перейти'),
          ),
        ],
      );
    }

    final cardColor = completed ? Colors.green[700]! : Colors.grey[850]!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: responsiveSize(context, 24)),
      padding: responsiveAll(context, 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeInOut);
          final scale = Tween<double>(begin: 0.95, end: 1.0).animate(curved);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
        child: completed ? buildCompleted() : buildActive(),
      ),
    );
  }
}

