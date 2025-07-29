import 'package:flutter/material.dart';

import '../models/theory_mini_lesson_node.dart';
import '../models/theory_cluster_summary.dart';
import '../services/theory_lesson_navigator_service.dart';
import '../services/tag_mastery_service.dart';
import '../widgets/tag_badge.dart';

/// Displays a recap after completing a [TheoryMiniLessonNode].
class TheoryRecapScreen extends StatelessWidget {
  final TheoryMiniLessonNode lesson;
  final TheoryClusterSummary? cluster;
  final TheoryLessonNavigatorService? navigator;
  final TagMasteryService? masteryService;
  final VoidCallback? onContinue;
  final VoidCallback? onReviewAgain;
  final VoidCallback? onGoToPath;

  const TheoryRecapScreen({
    super.key,
    required this.lesson,
    this.cluster,
    this.navigator,
    this.masteryService,
    this.onContinue,
    this.onReviewAgain,
    this.onGoToPath,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final next = navigator?.getNext(lesson.id);
    final clusterLabel = cluster != null && cluster!.sharedTags.isNotEmpty
        ? cluster!.sharedTags.join(', ')
        : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Theory Recap')),
      backgroundColor: const Color(0xFF121212),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${lesson.resolvedTitle} \u2014 \u2713',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (lesson.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: -4,
                children: [for (final t in lesson.tags) TagBadge(t)],
              ),
            ],
            if (clusterLabel != null) ...[
              const SizedBox(height: 8),
              Text(
                'Cluster: $clusterLabel',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            const Spacer(),
            if (next != null) ...[
              Text(
                'Next: ${next.resolvedTitle}',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onContinue ?? () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: accent),
                    child: Text(next != null ? 'Continue' : 'Done'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReviewAgain ?? () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent,
                      side: BorderSide(color: accent),
                    ),
                    child: const Text('Review again'),
                  ),
                ),
              ],
            ),
            if (onGoToPath != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onGoToPath,
                  child: const Text('Go to path'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
