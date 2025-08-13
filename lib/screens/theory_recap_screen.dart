import 'package:flutter/material.dart';

import '../models/theory_mini_lesson_node.dart';
import '../models/theory_cluster_summary.dart';
import '../services/theory_lesson_graph_navigator_service.dart';
import '../services/tag_mastery_service.dart';
import '../widgets/tag_badge.dart';
import '../widgets/booster_recommendation_banner.dart';
import '../services/theory_booster_recommender.dart';

/// Displays a recap after completing a [TheoryMiniLessonNode].
class TheoryRecapScreen extends StatefulWidget {
  final TheoryMiniLessonNode lesson;
  final TheoryClusterSummary? cluster;
  final TheoryLessonGraphNavigatorService? navigator;
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
    this.boosterRecommendation,
  });

  final BoosterRecommendationResult? boosterRecommendation;

  @override
  State<TheoryRecapScreen> createState() => _TheoryRecapScreenState();
}

class _TheoryRecapScreenState extends State<TheoryRecapScreen> {
  bool _showBooster = true;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final next = widget.navigator?.getNext(widget.lesson.id);
    final clusterLabel =
        widget.cluster != null && widget.cluster!.sharedTags.isNotEmpty
            ? widget.cluster!.sharedTags.join(', ')
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
              '${widget.lesson.resolvedTitle} \u2014 \u2713',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.lesson.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: -4,
                children: [for (final t in widget.lesson.tags) TagBadge(t)],
              ),
            ],
            if (clusterLabel != null) ...[
              const SizedBox(height: 8),
              Text(
                'Cluster: $clusterLabel',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            if (_showBooster && widget.boosterRecommendation != null) ...[
              const SizedBox(height: 12),
              BoosterRecommendationBanner(
                recommendation: widget.boosterRecommendation!,
                onStarted: () => setState(() => _showBooster = false),
                onDismissed: () => setState(() => _showBooster = false),
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
                    onPressed:
                        widget.onContinue ?? () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: accent),
                    child: Text(next != null ? 'Continue' : 'Done'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        widget.onReviewAgain ?? () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent,
                      side: BorderSide(color: accent),
                    ),
                    child: const Text('Review again'),
                  ),
                ),
              ],
            ),
            if (widget.onGoToPath != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: widget.onGoToPath,
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
