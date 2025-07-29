import 'package:flutter/material.dart';

import '../models/theory_lesson_cluster.dart';
import '../services/theory_cluster_progress_service.dart';

/// Card showing cluster tags, lesson count and progress bar.
class TheoryClusterSummaryCard extends StatelessWidget {
  final ClusterProgress progress;
  final VoidCallback? onTap;

  const TheoryClusterSummaryCard({
    super.key,
    required this.progress,
    this.onTap,
  });

  TheoryLessonCluster get cluster => progress.cluster;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final tags = cluster.tags.join(', ');
    final percent = progress.percent.clamp(0.0, 1.0);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tags.isNotEmpty ? tags : 'Cluster',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${progress.completed} / ${progress.total} lessons',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
