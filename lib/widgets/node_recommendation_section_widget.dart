import 'package:flutter/material.dart';

import '../models/training_path_node.dart';
import 'training_node_summary_card.dart';

/// Displays a compact section of recommended training path nodes.
///
/// Renders a title followed by up to three [TrainingNodeSummaryCard] widgets.
/// Tapping a card is only enabled when the node is unlocked. An optional
/// [onNodeTap] callback can be provided to handle taps.
class NodeRecommendationSectionWidget extends StatelessWidget {
  final List<TrainingPathNode> nodes;
  final Set<String> unlockedNodeIds;
  final Set<String> completedNodeIds;
  final String title;
  final void Function(TrainingPathNode node)? onNodeTap;

  const NodeRecommendationSectionWidget({
    super.key,
    required this.nodes,
    required this.unlockedNodeIds,
    required this.completedNodeIds,
    required this.title,
    this.onNodeTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayNodes = nodes.take(3).toList();
    if (displayNodes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final node in displayNodes)
          TrainingNodeSummaryCard(
            node: node,
            isUnlocked: unlockedNodeIds.contains(node.id),
            isCompleted: completedNodeIds.contains(node.id),
            onTap: unlockedNodeIds.contains(node.id)
                ? () => onNodeTap?.call(node)
                : null,
          ),
      ],
    );
  }
}
