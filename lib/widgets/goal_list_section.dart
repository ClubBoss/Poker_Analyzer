import 'package:flutter/material.dart';

import '../models/theory_goal.dart';
import '../services/theory_goal_engine.dart';
import 'theory_goal_widget.dart';

/// Section widget that displays all active [TheoryGoal]s in a vertical list.
class GoalListSection extends StatefulWidget {
  /// Optional callback when a goal is tapped.
  final void Function(TheoryGoal goal)? onTap;

  /// Message displayed when no goals are available.
  final String emptyMessage;

  const GoalListSection({
    super.key,
    this.onTap,
    this.emptyMessage = 'Нет целей',
  });

  @override
  State<GoalListSection> createState() => _GoalListSectionState();
}

class _GoalListSectionState extends State<GoalListSection> {
  late Future<List<TheoryGoal>> _future;

  @override
  void initState() {
    super.initState();
    _future = TheoryGoalEngine.instance.getActiveGoals();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TheoryGoal>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final goals = snapshot.data ?? const <TheoryGoal>[];
        if (goals.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.emptyMessage,
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: goals.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final goal = goals[i];
            return TheoryGoalWidget(
              goal: goal,
              onTap: () => widget.onTap?.call(goal),
            );
          },
        );
      },
    );
  }
}
