import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/goal.dart';
import '../services/goal_engine.dart';
import '../services/streak_service.dart';
import '../widgets/sync_status_widget.dart';

class GoalCard extends StatefulWidget {
  final Goal goal;
  final Color accent;
  const GoalCard({super.key, required this.goal, required this.accent});

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
    if (widget.goal.completed) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant GoalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.goal.completed && !oldWidget.goal.completed) {
      _controller.forward(from: 0);
    } else if (!widget.goal.completed && oldWidget.goal.completed) {
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
    final progress =
        (widget.goal.currentXP / widget.goal.targetXP).clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glow = math.sin(_controller.value * math.pi);
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.goal.completed ? Colors.green[700] : Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
            boxShadow: widget.goal.completed
                ? [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: glow),
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
          Text(
            widget.goal.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.goal.completed ? Colors.white70 : Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: widget.goal.completed ? 1.0 : progress,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(widget.accent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${widget.goal.currentXP}/${widget.goal.targetXP}'),
          )
        ],
      ),
    );
  }
}

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  void _showBonusInfo(BuildContext context) {
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
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final bonus = context.watch<StreakService>().hasBonus;
    final goals = context.watch<GoalEngine>().goals;
    final children = <Widget>[];
    if (bonus) {
      children.add(
        InkWell(
          onTap: () => _showBonusInfo(context),
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
                    '🔥 Бонус за серию - ускоренный прогресс целей!',
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
    for (final g in goals) {
      children.add(GoalCard(goal: g, accent: accent));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои цели'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: children,
      ),
    );
  }
}
