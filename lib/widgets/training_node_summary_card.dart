import 'package:flutter/material.dart';

import '../models/training_path_node.dart';

/// A compact card summarizing a training path node.
///
/// Displays the node title and an icon indicating whether the node is
/// locked, unlocked, or completed. When [onTap] is provided the card becomes
/// tappable, allowing the caller to open the node's entry point.
class TrainingNodeSummaryCard extends StatelessWidget {
  final TrainingPathNode node;
  final bool isUnlocked;
  final bool isCompleted;
  final VoidCallback? onTap;

  const TrainingNodeSummaryCard({
    super.key,
    required this.node,
    required this.isUnlocked,
    required this.isCompleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget statusIcon;
    if (isCompleted) {
      statusIcon =
          const Icon(Icons.check_circle, color: Colors.green, size: 18);
    } else {
      final color = isUnlocked ? Colors.blue : Colors.grey;
      statusIcon = Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              statusIcon,
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.title,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              if (onTap != null) const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
