import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/training_goal.dart';
import '../services/goal_reminder_engine.dart';
import '../services/goal_suggestion_service.dart';
import '../services/pack_library_service.dart';
import '../services/session_log_service.dart';
import '../services/tag_mastery_service.dart';
import '../services/training_session_launcher.dart';
import '../services/goal_engagement_tracker.dart';
import '../models/goal_engagement.dart';

class SmartGoalBanner extends StatefulWidget {
  const SmartGoalBanner({super.key});

  @override
  State<SmartGoalBanner> createState() => _SmartGoalBannerState();
}

class _SmartGoalBannerState extends State<SmartGoalBanner> {
  bool _loading = true;
  TrainingGoal? _goal;
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final engine = GoalReminderEngine(
      suggestions: GoalSuggestionService(
        mastery: context.read<TagMasteryService>(),
      ),
      logs: context.read<SessionLogService>(),
    );
    final goals = await engine.getStaleGoals();
    if (!mounted) return;
    setState(() {
      _goal = goals.isNotEmpty ? goals.first : null;
      _loading = false;
    });
  }

  Future<void> _continue() async {
    final g = _goal;
    if (g == null || g.tag == null) return;
    final pack = await PackLibraryService.instance.findByTag(g.tag!);
    if (pack == null) return;
    await GoalEngagementTracker.instance.log(
      GoalEngagement(tag: g.tag!, action: 'start', timestamp: DateTime.now()),
    );
    await const TrainingSessionLauncher().launch(pack);
  }

  void _dismiss() async {
    final g = _goal;
    if (g != null && g.tag != null) {
      await GoalEngagementTracker.instance.log(
        GoalEngagement(
          tag: g.tag!,
          action: 'dismiss',
          timestamp: DateTime.now(),
        ),
      );
    }
    setState(() => _hidden = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _hidden || _goal == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    final g = _goal!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                    if (g.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          g.description,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: _dismiss,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _continue,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text('Продолжить'),
            ),
          ),
        ],
      ),
    );
  }
}
