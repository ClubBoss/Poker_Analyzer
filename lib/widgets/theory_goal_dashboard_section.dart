import 'package:flutter/material.dart';

import '../models/theory_goal.dart';
import '../services/theory_goal_engine.dart';
import 'goal_list_section.dart';

/// Dashboard card displaying active [TheoryGoal]s with an optional refresh
/// action.
class TheoryGoalDashboardSection extends StatefulWidget {
  /// Callback when a goal is tapped.
  final void Function(TheoryGoal goal)? onTap;

  /// Whether to show the refresh button.
  final bool showRefresh;

  const TheoryGoalDashboardSection({
    super.key,
    this.onTap,
    this.showRefresh = true,
  });

  @override
  State<TheoryGoalDashboardSection> createState() =>
      _TheoryGoalDashboardSectionState();
}

class _TheoryGoalDashboardSectionState
    extends State<TheoryGoalDashboardSection> {
  bool _refreshing = false;
  Key _listKey = UniqueKey();

  Future<void> _refreshGoals() async {
    setState(() => _refreshing = true);
    await TheoryGoalEngine.instance.refreshGoals();
    if (!mounted) return;
    setState(() {
      _refreshing = false;
      _listKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.all(16),
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
              const Expanded(
                child: Text(
                  '📚 Цели обучения',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              if (widget.showRefresh)
                ElevatedButton(
                  onPressed: _refreshing ? null : _refreshGoals,
                  style: ElevatedButton.styleFrom(backgroundColor: accent),
                  child: _refreshing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('🔄 Обновить'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GoalListSection(
            key: _listKey,
            onTap: widget.onTap,
            emptyMessage: 'Цели скоро появятся!',
          ),
        ],
      ),
    );
  }
}
