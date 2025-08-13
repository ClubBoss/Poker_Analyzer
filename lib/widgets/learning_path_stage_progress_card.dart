import 'package:flutter/material.dart';

import '../models/learning_path_stage_model.dart';
import '../models/theory_pack_model.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../theme/app_colors.dart';
import 'tag_badge.dart';
import 'tag_progress_chip.dart';

/// Compact card showing progress for a single learning path stage.
class LearningPathStageProgressCard extends StatelessWidget {
  /// Stage being summarized.
  final LearningPathStageModel stage;

  /// Current progress [0..1].
  final double progress;

  /// Optional training pack providing spot count.
  final TrainingPackTemplateV2? pack;

  /// Optional theory pack providing section count.
  final TheoryPackModel? theoryPack;

  /// Callback when user taps the card.
  final VoidCallback? onTap;

  /// Whether to use a compact layout with max height of 140.
  final bool compact;

  /// Per-tag progress values for this stage.
  final Map<String, double>? tagProgress;

  const LearningPathStageProgressCard({
    super.key,
    required this.stage,
    required this.progress,
    this.pack,
    this.theoryPack,
    this.onTap,
    this.compact = false,
    this.tagProgress,
  });

  String _infoLabel() {
    if (pack != null) {
      return '${pack!.spotCount} рук';
    }
    if (theoryPack != null) {
      return '${theoryPack!.sections.length} секций';
    }
    return '${stage.minHands} рук';
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final pct = (progress.clamp(0.0, 1.0) * 100).round();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: compact
            ? const BoxConstraints(maxHeight: 140)
            : const BoxConstraints(),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stage.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (stage.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  stage.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '$pct%',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  _infoLabel(),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            if (tagProgress != null && tagProgress!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 4,
                  runSpacing: -4,
                  children: [
                    for (final e in tagProgress!.entries.take(6))
                      TagProgressChip(tag: e.key, progress: e.value),
                  ],
                ),
              )
            else if (stage.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 4,
                  runSpacing: -4,
                  children: [for (final t in stage.tags.take(3)) TagBadge(t)],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
