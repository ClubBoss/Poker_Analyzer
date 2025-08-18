import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/scheduled_training_queue_service.dart';
import '../services/tag_insight_reminder_engine.dart';
import '../services/session_log_service.dart';
import '../services/pack_library_loader_service.dart';
import '../services/weakness_cluster_engine_v2.dart';
import '../services/tag_goal_tracker_service.dart';
import '../models/training_attempt.dart';
import '../services/review_path_recommender.dart';

class SmartRecoveryBanner extends StatefulWidget {
  const SmartRecoveryBanner({super.key});

  @override
  State<SmartRecoveryBanner> createState() => _SmartRecoveryBannerState();
}

class _SmartRecoveryBannerState extends State<SmartRecoveryBanner> {
  late Future<bool> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _check();
  }

  Future<bool> _check() async {
    final queue = ScheduledTrainingQueueService.instance;
    await queue.load();
    return queue.queue.isEmpty;
  }

  Future<void> _generate() async {
    setState(() => _busy = true);
    final queue = ScheduledTrainingQueueService.instance;

    final losses = await context.read<TagInsightReminderEngine>().loadLosses();

    final logs = context.read<SessionLogService>();
    await logs.load();
    final attempts = [
      for (final log in logs.logs)
        TrainingAttempt(
          packId: log.templateId,
          spotId: log.templateId,
          timestamp: log.completedAt,
          accuracy: (log.correctCount + log.mistakeCount) == 0
              ? 0
              : log.correctCount / (log.correctCount + log.mistakeCount),
          ev: 0,
          icm: 0,
        ),
    ];

    await PackLibraryLoaderService.instance.loadLibrary();
    final packs = PackLibraryLoaderService.instance.library;

    final clusters = const WeaknessClusterEngine()
        .computeClusters(attempts: attempts, allPacks: packs)
        .take(3)
        .map((c) => MistakeCluster(tag: c.label, count: c.spotIds.length))
        .toList();

    final tracker = TagGoalTrackerService.instance;
    final missRates = <String, double>{};
    final tags = <String>{
      for (final p in packs) ...p.tags.map((e) => e.trim().toLowerCase()),
    };
    for (final t in tags) {
      final prog = await tracker.getProgress(t);
      final rate = (1 - prog.trainings / 10).clamp(0.0, 1.0);
      missRates[t] = rate;
    }

    await queue.autoSchedule(
      losses: losses,
      mistakeClusters: clusters,
      goalMissRatesByTag: missRates,
    );

    setState(() {
      _future = _check();
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<bool>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data! || _busy) {
          return const SizedBox.shrink();
        }
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Нет запланированных тренировок. Сгенерировать план?',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: _generate,
                style: ElevatedButton.styleFrom(backgroundColor: accent),
                child: const Text('🧠 Generate Recovery Plan'),
              ),
            ],
          ),
        );
      },
    );
  }
}
