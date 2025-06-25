import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/goals_service.dart';

enum _GoalFilter { all, completed, active }

class GoalHistoryScreen extends StatefulWidget {
  const GoalHistoryScreen({super.key});

  @override
  State<GoalHistoryScreen> createState() => _GoalHistoryScreenState();
}

class _GoalHistoryScreenState extends State<GoalHistoryScreen> {
  _GoalFilter _filter = _GoalFilter.all;

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<GoalsService>();
    final accent = Theme.of(context).colorScheme.secondary;
    final goals = service.goals;

    List<Goal> filteredGoals;
    switch (_filter) {
      case _GoalFilter.completed:
        filteredGoals = goals.where((g) => g.completed).toList();
        break;
      case _GoalFilter.active:
        filteredGoals = goals.where((g) => !g.completed).toList();
        break;
      case _GoalFilter.all:
      default:
        filteredGoals = goals;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('История целей'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: ToggleButtons(
              isSelected: [
                _filter == _GoalFilter.all,
                _filter == _GoalFilter.completed,
                _filter == _GoalFilter.active,
              ],
              onPressed: (index) {
                setState(() => _filter = _GoalFilter.values[index]);
              },
              borderRadius: BorderRadius.circular(4),
              selectedColor: Colors.white,
              fillColor: Colors.blueGrey,
              color: Colors.white70,
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Все'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Завершённые'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Активные'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredGoals.length,
              itemBuilder: (context, index) {
                final g = filteredGoals[index];
          final completed = g.progress >= g.target;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (g.icon != null) ...[
                  Icon(g.icon, color: accent),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (completed && g.completedAt != null)
                        Text('Завершено: ${_formatDate(g.completedAt!)}')
                      else
                        Text('${g.progress}/${g.target}')
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  completed ? Icons.check_circle : Icons.timelapse,
                  color: completed ? Colors.green : Colors.grey,
                ),
              ],
            ),
          );
        },
      ),
    ),
  ],
),
    );
  }
}
