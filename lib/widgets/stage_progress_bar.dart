import 'package:flutter/material.dart';

import '../models/skill_tree.dart';

/// Shows progress within the current active stage of a [SkillTree].
class StageProgressBar extends StatelessWidget {
  final SkillTree tree;
  final Set<String> completedNodeIds;

  const StageProgressBar({
    super.key,
    required this.tree,
    required this.completedNodeIds,
  });

  int _activeStage() {
    final unlocked = <int>{};
    for (final node in tree.nodes.values) {
      if (node.prerequisites.isEmpty ||
          node.prerequisites.every(completedNodeIds.contains)) {
        unlocked.add(node.level);
      }
    }
    var level = 0;
    for (final l in unlocked) {
      if (l > level) level = l;
    }
    return level;
  }

  @override
  Widget build(BuildContext context) {
    if (tree.nodes.isEmpty) return const SizedBox.shrink();
    final level = _activeStage();
    final nodes = tree.nodes.values.where((n) => n.level == level);
    final filtered = nodes
        .where((n) => (n as dynamic).isOptional != true)
        .toList();
    final total = filtered.length;
    final done = filtered.where((n) => completedNodeIds.contains(n.id)).length;
    final progress = total > 0 ? done / total : 0.0;
    final accent = Theme.of(context).colorScheme.secondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Этап $level: $done из $total',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(accent),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
