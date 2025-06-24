import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../services/streak_service.dart';

class Goal {
  final String title;
  final int progress;
  final int target;
  final IconData? icon;

  const Goal({
    required this.title,
    required this.progress,
    required this.target,
    this.icon,
  });
}

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  static const List<Goal> _initialGoals = [
    Goal(
      title: 'Разобрать 5 ошибок',
      progress: 2,
      target: 5,
      icon: Icons.bug_report,
    ),
    Goal(
      title: 'Пройти 3 раздачи без ошибок подряд',
      progress: 1,
      target: 3,
      icon: Icons.play_circle_fill,
    ),
  ];

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class GoalCard extends StatefulWidget {
  final Goal goal;
  final double progress;
  final int displayProgress;
  final bool completed;
  final Color accent;
  final VoidCallback? onReset;

  const GoalCard({
    super.key,
    required this.goal,
    required this.progress,
    required this.displayProgress,
    required this.completed,
    required this.accent,
    this.onReset,
  });

  @override
  State<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<GoalCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.completed) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant GoalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.completed && !oldWidget.completed) {
      _controller.forward(from: 0);
    } else if (!widget.completed && oldWidget.completed) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glow = math.sin(_controller.value * math.pi);
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.completed ? Colors.green[700] : Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
            boxShadow: widget.completed
                ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(glow),
                      blurRadius: 20 * glow,
                      spreadRadius: 2 * glow,
                    )
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.goal.icon != null) ...[
                Icon(widget.goal.icon, color: widget.accent),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  widget.goal.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        widget.completed ? Colors.white70 : Colors.white,
                  ),
                ),
              ),
              if (widget.completed) ...[
                const Icon(Icons.check_circle, color: Colors.green),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Сбросить цель',
                  style: IconButton.styleFrom(shape: const CircleBorder()),
                  onPressed: widget.onReset,
                ),
              ] else
                Text('${widget.displayProgress}/${widget.goal.target}')
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: widget.completed ? 1.0 : widget.progress,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(widget.accent),
              minHeight: 6,
            ),
          )
        ],
      ),
    );
  }
}

class _GoalsScreenState extends State<GoalsScreen> {
  late List<Goal> _goals;

  void _showBonusInfo() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Бонус за серию',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Получите ×1.5 прогресс целей, если заходите 3 дня подряд. Стрик не должен прерываться.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _goals = List<Goal>.from(GoalsScreen._initialGoals);
  }

  void _resetGoal(int index) {
    final goal = _goals[index];
    setState(() {
      _goals[index] = Goal(
        title: goal.title,
        progress: 0,
        target: goal.target,
        icon: goal.icon,
      );
    });
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Цель сброшена')));
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final bonus = context.watch<StreakService>().hasBonus;
    final multiplier = bonus ? StreakService.bonusMultiplier : 1.0;

    List<Widget> children = [];
    if (bonus) {
      children.add(
        InkWell(
          onTap: _showBonusInfo,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[700],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.local_fire_department, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🔥 Бонус за серию — ускоренный прогресс целей!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final List<Widget> activeGoals = [];
    final List<Widget> completedGoals = [];

    for (int index = 0; index < _goals.length; index++) {
      final goal = _goals[index];
      final adjusted = math.min((goal.progress * multiplier).round(), goal.target);
      final progress = (adjusted / goal.target).clamp(0.0, 1.0);
      final isCompleted = goal.progress >= goal.target;

      final card = GoalCard(
        goal: goal,
        progress: progress,
        displayProgress: adjusted,
        completed: isCompleted,
        accent: accent,
        onReset: isCompleted ? () => _resetGoal(index) : null,
      );

      if (isCompleted) {
        completedGoals.add(card);
      } else {
        activeGoals.add(card);
      }
    }

    children.addAll(activeGoals);
    children.addAll(completedGoals);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои цели'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: children,
      ),
    );
  }
}
