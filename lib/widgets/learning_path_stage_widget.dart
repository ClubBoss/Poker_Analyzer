import 'package:flutter/material.dart';

import '../models/learning_path_stage_model.dart';
import 'tag_badge.dart';

/// Reusable widget displaying a single stage of a learning path.
class LearningPathStageWidget extends StatelessWidget {
  final LearningPathStageModel stage;
  final double progress;
  final int handsPlayed;
  final bool unlocked;
  final bool recommended;
  final VoidCallback onPressed;

  const LearningPathStageWidget({
    super.key,
    required this.stage,
    required this.progress,
    required this.handsPlayed,
    required this.unlocked,
    this.recommended = false,
    required this.onPressed,
  });

  String _ctaLabel() {
    if (!unlocked) return 'Заблокировано';
    if (progress >= 1.0) return 'Завершено';
    if (progress > 0.0) return 'Продолжить';
    return 'Начать';
  }

  Color _progressColor(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    if (progress >= 1.0) return Colors.green;
    if (progress > 0.0) return accent;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final pctText = '${(progress.clamp(0.0, 1.0) * 100).round()}%';
    final accent = Theme.of(context).colorScheme.secondary;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      shape: recommended
          ? RoundedRectangleBorder(
              side: BorderSide(color: accent, width: 2),
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$handsPlayed/${stage.minHands}',
                        style: const TextStyle(color: Colors.white70)),
                    Text(pctText,
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
            if (stage.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 4,
                  runSpacing: -4,
                  children: [for (final t in stage.tags) TagBadge(t)],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white24,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(_progressColor(context)),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: !unlocked || progress >= 1.0 ? null : onPressed,
                child: Text(_ctaLabel()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
