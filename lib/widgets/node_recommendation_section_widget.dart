import 'package:flutter/material.dart';

import '../models/training_path_node.dart';
import '../services/node_recommendation_service.dart';
import 'training_node_summary_card.dart';

/// Displays a compact section of recommended training path nodes.
///
/// Renders a title followed by up to three [TrainingNodeSummaryCard] widgets.
/// Tapping a card is only enabled when the node is unlocked. An optional
/// [onNodeTap] callback can be provided to handle taps.
class NodeRecommendationSectionWidget extends StatelessWidget {
  final List<NodeRecommendation> recommendations;
  final Set<String> unlockedNodeIds;
  final Set<String> completedNodeIds;
  final String title;
  final void Function(TrainingPathNode node)? onNodeTap;

  const NodeRecommendationSectionWidget({
    super.key,
    required this.recommendations,
    required this.unlockedNodeIds,
    required this.completedNodeIds,
    required this.title,
    this.onNodeTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayRecs = recommendations.take(3).toList();
    if (displayRecs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final rec in displayRecs) ...[
          TrainingNodeSummaryCard(
            node: rec.node,
            isUnlocked: unlockedNodeIds.contains(rec.node.id),
            isCompleted: completedNodeIds.contains(rec.node.id),
            onTap: unlockedNodeIds.contains(rec.node.id)
                ? () => onNodeTap?.call(rec.node)
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            rec.reason,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
