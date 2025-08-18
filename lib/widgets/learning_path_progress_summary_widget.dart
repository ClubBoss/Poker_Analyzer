import 'package:flutter/material.dart';

import '../models/learning_path_template_v2.dart';
import '../services/learning_path_stage_completion_engine.dart';

/// Compact summary widget showing overall progress for a learning path.
class LearningPathProgressSummaryWidget extends StatelessWidget {
  final LearningPathTemplateV2 template;
  final Map<String, int> handsPlayedByPackId;
  final VoidCallback? onPressed;

  const LearningPathProgressSummaryWidget({
    super.key,
    required this.template,
    required this.handsPlayedByPackId,
    this.onPressed,
  });

  int _completedStages() {
    const engine = LearningPathStageCompletionEngine();
    var completed = 0;
    for (final stage in template.stages) {
      final hands = handsPlayedByPackId[stage.packId] ?? 0;
      if (engine.isStageComplete(stage, hands)) completed++;
    }
    return completed;
  }

  int _totalHandsRequired() {
    var total = 0;
    for (final s in template.stages) {
      total += s.minHands;
    }
    return total;
  }

  int _totalHandsPlayed() {
    var total = 0;
    for (final s in template.stages) {
      total += handsPlayedByPackId[s.packId] ?? 0;
    }
    return total;
  }

  double _overallProgress() {
    if (template.stages.isEmpty) return 0.0;
    var sum = 0.0;
    for (final s in template.stages) {
      if (s.minHands <= 0) continue;
      final hands = handsPlayedByPackId[s.packId] ?? 0;
      final ratio = hands / s.minHands;
      sum += ratio.clamp(0.0, 1.0);
    }
    return sum / template.stages.length;
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final completed = _completedStages();
    final totalStages = template.stages.length;
    final played = _totalHandsPlayed();
    final required = _totalHandsRequired();
    final progress = _overallProgress();
    final pct = (progress.clamp(0.0, 1.0) * 100).round();
    final finished = completed >= totalStages && totalStages > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            template.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '$completed/$totalStages стадий',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            '$played/$required рук',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
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
          Text('$pct%', style: const TextStyle(color: Colors.white70)),
          if (onPressed != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onPressed,
                style: TextButton.styleFrom(foregroundColor: accent),
                child: Text(finished ? 'Review' : 'Continue'),
              ),
            ),
        ],
      ),
    );
  }
}
