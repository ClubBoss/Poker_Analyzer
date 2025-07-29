import 'package:flutter/material.dart';

import '../models/theory_lesson_cluster.dart';
import '../services/theory_cluster_progress_service.dart';
import '../theme/app_colors.dart';
import 'tag_badge.dart';

/// Compact card widget displaying visual summary for a theory lesson cluster.
class TheoryClusterSummaryCard extends StatelessWidget {
  /// Cluster being displayed.
  final TheoryLessonCluster cluster;

  /// Completion stats for this cluster.
  final ClusterProgress progress;

  /// Callback when the card or action button is tapped.
  final VoidCallback? onTap;

  const TheoryClusterSummaryCard({
    super.key,
    required this.cluster,
    required this.progress,
    this.onTap,
  });

  String _title() {
    if (cluster.tags.isNotEmpty) return cluster.tags.first;
    if (cluster.lessons.isNotEmpty) return cluster.lessons.first.resolvedTitle;
    return '';
  }

  Color _progressColor() {
    final p = progress.percent.clamp(0.0, 1.0);
    return Color.lerp(Colors.red, Colors.green, p) ?? Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final pct = (progress.percent.clamp(0.0, 1.0) * 100).round();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _title(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (cluster.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  runSpacing: -4,
                  children: [for (final t in cluster.tags) TagBadge(t)],
                ),
              ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.percent.clamp(0.0, 1.0),
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(_progressColor()),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${progress.completed} из ${progress.total} · $pct%',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onTap,
                  child: const Text('Открыть'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
