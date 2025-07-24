import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/goal_progress.dart';
import '../models/goal_engagement.dart';
import '../services/smart_goal_reminder_engine.dart';
import '../services/smart_goal_tracking_service.dart';
import '../services/session_log_service.dart';
import '../services/pack_library_loader_service.dart';
import '../services/pack_library_service.dart';
import '../services/goal_engagement_tracker.dart';
import '../services/learning_path_service.dart';
import '../services/training_session_launcher.dart';

class GoalReminderBanner extends StatefulWidget {
  const GoalReminderBanner({super.key});

  @override
  State<GoalReminderBanner> createState() => _GoalReminderBannerState();
}

class _GoalReminderBannerState extends State<GoalReminderBanner> {
  bool _loading = true;
  String? _tag;
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!LearningPathService.instance.smartMode) {
      setState(() => _loading = false);
      return;
    }
    await PackLibraryLoaderService.instance.loadLibrary();
    final packs = PackLibraryLoaderService.instance.library;
    final tags = <String>{};
    for (final p in packs) {
      tags.addAll(p.tags.map((e) => e.trim().toLowerCase()));
    }
    final tracker = SmartGoalTrackingService(
      logs: context.read<SessionLogService>(),
    );
    final goals = <GoalProgress>[];
    for (final t in tags) {
      final g = await tracker.getGoalProgress(t);
      goals.add(g);
    }
    final log = await GoalEngagementTracker.instance.getAll();
    const engine = SmartGoalReminderEngine();
    final stale = await engine.getStaleGoalTags(
      allGoals: goals,
      engagementLog: log,
    );
    if (!mounted) return;
    setState(() {
      _tag = stale.isNotEmpty ? stale.first : null;
      _loading = false;
    });
  }

  Future<void> _start() async {
    final tag = _tag;
    if (tag == null) return;
    final pack = await PackLibraryService.instance.findByTag(tag);
    if (pack == null) return;
    await GoalEngagementTracker.instance.log(
      GoalEngagement(tag: tag, action: 'start', timestamp: DateTime.now()),
    );
    await const TrainingSessionLauncher().launch(pack);
  }

  void _dismiss() async {
    final tag = _tag;
    if (tag != null) {
      await GoalEngagementTracker.instance.log(
        GoalEngagement(tag: tag, action: 'dismiss', timestamp: DateTime.now()),
      );
    }
    setState(() => _hidden = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _hidden || _tag == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    final tag = _tag!;
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
                      'Вы давно не тренировались по цели: $tag',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Нажмите, чтобы продолжить обучение',
                        style: TextStyle(color: Colors.white70),
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
              onPressed: _start,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text('Начать'),
            ),
          ),
        ],
      ),
    );
  }
}
