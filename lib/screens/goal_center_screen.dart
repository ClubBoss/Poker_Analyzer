import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/training_goal.dart';
import '../models/goal_progress.dart';
import '../services/goal_suggestion_service.dart';
import '../services/session_log_service.dart';
import '../services/tag_mastery_service.dart';
import '../services/pack_library_service.dart';
import '../services/training_session_launcher.dart';
import '../services/smart_goal_tracking_service.dart';
import '../services/goal_completion_engine.dart';
import '../services/goal_completion_event_service.dart';
import '../widgets/training_goal_card.dart';
import '../utils/snackbar_util.dart';

class GoalCenterScreen extends StatefulWidget {
  static const route = '/goals';
  const GoalCenterScreen({super.key});

  @override
  State<GoalCenterScreen> createState() => _GoalCenterScreenState();
}

class _GoalCenterScreenState extends State<GoalCenterScreen> {
  List<TrainingGoal>? _goals;
  final Map<String, GoalProgress> _progress = {};
  final GoalCompletionEngine _completionEngine = GoalCompletionEngine.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final progress = await context.read<SessionLogService>().getUserProgress();
    final service = GoalSuggestionService(
      mastery: context.read<TagMasteryService>(),
    );
    final goals = await service.suggestGoals(progress: progress);
    final tracker =
        SmartGoalTrackingService(logs: context.read<SessionLogService>());
    final map = <String, GoalProgress>{};
    final filtered = <TrainingGoal>[];
    for (final g in goals) {
      final tag = g.tag;
      if (tag != null) {
        final prog = await tracker.getGoalProgress(tag);
        await GoalCompletionEventService.instance.logIfNew(prog);
        map[tag] = prog;
        if (_completionEngine.showCompletedGoals ||
            !_completionEngine.isGoalCompleted(prog)) {
          filtered.add(g);
        }
      } else {
        filtered.add(g);
      }
    }
    if (!mounted) return;
    setState(() {
      _goals = filtered;
      _progress
        ..clear()
        ..addAll(map);
    });
  }

  Future<void> _startGoal(TrainingGoal goal) async {
    if (goal.tag == null) return;
    final pack = await PackLibraryService.instance.findByTag(goal.tag!);
    if (pack == null) {
      if (!mounted) return;
      SnackbarUtil.showMessage(context, 'Тренировка не найдена');
      return;
    }
    await const TrainingSessionLauncher().launch(pack);
  }

  @override
  Widget build(BuildContext context) {
    final goals = _goals;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Центр целей'),
      ),
      body: goals == null
          ? const Center(child: CircularProgressIndicator())
          : goals.isEmpty
              ? const Center(
                  child: Text(
                    'Нет персональных целей',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    final g = goals[index];
                    return TrainingGoalCard(
                      goal: g,
                      onStart: () => _startGoal(g),
                      progress: g.tag != null ? _progress[g.tag] : null,
                    );
                  },
                ),
    );
  }
}
