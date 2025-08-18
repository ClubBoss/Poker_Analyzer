import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_goal.dart';
import '../services/goal_suggestion_engine.dart';
import '../services/tag_mastery_service.dart';
import '../services/user_goal_engine.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  bool _loading = true;
  final List<UserGoal> _activeGoals = [];
  final List<UserGoal> _suggestedGoals = [];
  Map<String, double> _mastery = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final engine = context.read<UserGoalEngine>();
    final suggester = context.read<GoalSuggestionEngine>();
    final masteryService = context.read<TagMasteryService>();
    final mastery = await masteryService.computeMastery(force: true);
    final suggestions = await suggester.suggestGoals(force: true);
    setState(() {
      _activeGoals
        ..clear()
        ..addAll(engine.goals.where((g) => !g.completed));
      _suggestedGoals
        ..clear()
        ..addAll(suggestions);
      _mastery = mastery;
      _loading = false;
    });
  }

  double _goalProgress(UserGoal g) {
    if (g.tag != null && g.targetAccuracy != null) {
      final current = (_mastery[g.tag] ?? 0.0) * 100;
      final base = g.base.toDouble();
      final target = g.targetAccuracy!;
      if (target <= base) return 1.0;
      return ((current - base) / (target - base)).clamp(0.0, 1.0);
    }
    final engine = context.read<UserGoalEngine>();
    return (engine.progress(g) / g.target).clamp(0.0, 1.0);
  }

  Widget _activeTile(UserGoal g, Color accent) {
    final progress = _goalProgress(g);
    final text = g.tag != null && g.targetAccuracy != null
        ? '${((_mastery[g.tag] ?? 0.0) * 100).toStringAsFixed(0)}% / ${g.targetAccuracy!.toStringAsFixed(0)}%'
        : '${context.read<UserGoalEngine>().progress(g)}/${g.target}';
    return ListTile(
      title: Text(g.title),
      subtitle: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white24,
          valueColor: AlwaysStoppedAnimation<Color>(accent),
          minHeight: 6,
        ),
      ),
      trailing: Text(text, style: const TextStyle(color: Colors.white70)),
    );
  }

  Future<void> _acceptGoal(UserGoal g) async {
    await context.read<UserGoalEngine>().addGoal(g);
    await _load();
  }

  void _declineGoal(UserGoal g) {
    setState(() => _suggestedGoals.removeWhere((e) => e.id == g.id));
  }

  Widget _suggestedTile(UserGoal g, Color accent) {
    final progress = (_mastery[g.tag] ?? 0.0);
    return ListTile(
      title: Text('#${g.tag} - цель: ${g.targetAccuracy?.toStringAsFixed(0)}%'),
      subtitle: LinearProgressIndicator(value: progress),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _declineGoal(g),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _acceptGoal(g),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(title: const Text('🎯 Цели')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_activeGoals.isNotEmpty) ...[
                    const Text(
                      '🎯 Активные цели',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    for (final g in _activeGoals) ...[
                      _activeTile(g, accent),
                      const SizedBox(height: 12),
                    ],
                  ],
                  if (_suggestedGoals.isNotEmpty) ...[
                    if (_activeGoals.isNotEmpty) const SizedBox(height: 16),
                    const Text(
                      '✨ Предложенные цели',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    for (final g in _suggestedGoals) ...[
                      _suggestedTile(g, accent),
                      const SizedBox(height: 12),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}
