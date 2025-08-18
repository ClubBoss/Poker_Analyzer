import 'package:flutter/material.dart';

import '../models/learning_path_stage_model.dart';
import '../models/stage_type.dart';
import '../services/learning_path_stage_launcher.dart';
import '../services/theory_stage_progress_tracker.dart';
import '../services/training_progress_service.dart';
import '../theme/app_colors.dart';

/// Reusable tile displaying a learning path stage with progress and type icon.
class LearningPathStageTile extends StatelessWidget {
  /// Stage to display.
  final LearningPathStageModel stage;

  /// Optional launcher override for testing.
  final LearningPathStageLauncher launcher;

  const LearningPathStageTile({
    super.key,
    required this.stage,
    this.launcher = const LearningPathStageLauncher(),
  });

  Future<double> _loadProgress() async {
    if (stage.type == StageType.theory || stage.type == StageType.booster) {
      final done = await TheoryStageProgressTracker.instance.isCompleted(
        stage.id,
      );
      if (done) return 1.0;
      final mastery = await TheoryStageProgressTracker.instance.getMastery(
        stage.id,
      );
      return mastery.clamp(0.0, 1.0);
    }
    return TrainingProgressService.instance.getProgress(stage.packId);
  }

  IconData _iconFor(StageType type) {
    switch (type) {
      case StageType.theory:
        return Icons.menu_book;
      case StageType.booster:
        return Icons.bolt;
      case StageType.practice:
      default:
        return Icons.fitness_center;
    }
  }

  Color _colorFor(StageType type, BuildContext context) {
    switch (type) {
      case StageType.theory:
        return Colors.blue;
      case StageType.booster:
        return Colors.orange;
      case StageType.practice:
      default:
        return Theme.of(context).colorScheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(stage.type, context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.cardBackground,
      child: InkWell(
        onTap: () => launcher.launch(context, stage),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_iconFor(stage.type), color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (stage.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          stage.description,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    if (stage.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: -4,
                          children: [
                            for (final t in stage.tags) Chip(label: Text(t)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    FutureBuilder<double>(
                      future: _loadProgress(),
                      builder: (context, snapshot) {
                        final value = snapshot.data ?? 0.0;
                        final pct = (value.clamp(0.0, 1.0) * 100).round();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: value.clamp(0.0, 1.0),
                                backgroundColor: Colors.white24,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  color,
                                ),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '$pct%',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                if (value >= 1.0)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
