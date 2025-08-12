import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

import '../../models/learning_branch_node.dart';
import '../../models/learning_path_node.dart';
import '../../models/theory_lesson_node.dart';

/// Displays a graph of [LearningPathNode]s with the current node highlighted.
class PathMapVisualizer extends StatelessWidget {
  /// All nodes that make up the learning path.
  final List<LearningPathNode> nodes;

  /// Identifier of the node currently in focus.
  final String? currentNodeId;

  /// Callback when a node is tapped.
  final ValueChanged<String>? onNodeTap;

  const PathMapVisualizer({
    super.key,
    required this.nodes,
    required this.currentNodeId,
    this.onNodeTap,
  });

  @override
  Widget build(BuildContext context) {
    final graph = Graph();
    final map = <String, Node>{};

    for (final n in nodes) {
      final widget = _buildNode(context, n, n.id == currentNodeId);
      final node = Node(widget);
      map[n.id] = node;
      graph.addNode(node);
    }

    for (final n in nodes) {
      final from = map[n.id];
      if (from == null) continue;
      if (n is StageNode) {
        for (final id in n.nextIds) {
          final to = map[id];
          if (to != null) graph.addEdge(from, to);
        }
      } else if (n is TheoryLessonNode) {
        for (final id in n.nextIds) {
          final to = map[id];
          if (to != null) graph.addEdge(from, to);
        }
      } else if (n is LearningBranchNode) {
        for (final id in n.branches.values) {
          final to = map[id];
          if (to != null) graph.addEdge(from, to);
        }
      }
    }

    final builder = BuchheimWalkerAlgorithm(
      BuchheimWalkerConfiguration()
        ..siblingSeparation = 20
        ..levelSeparation = 40
        ..subtreeSeparation = 20,
    );

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(100),
      minScale: 0.1,
      maxScale: 2.0,
      child: GraphView(
        graph: graph,
        algorithm: builder,
      ),
    );
  }

  Widget _buildNode(BuildContext context, LearningPathNode node, bool current) {
    Color color;
    if (node is LearningBranchNode) {
      color = Colors.orange;
    } else if (node is TheoryLessonNode) {
      color = Colors.purple;
    } else {
      color = Colors.blue;
    }
    final border = current
        ? Border.all(color: Colors.red, width: 3)
        : Border.all(color: color);
    return GestureDetector(
      onTap: onNodeTap == null ? null : () => onNodeTap!(node.id),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: border,
        ),
        child: Text(node.id, textAlign: TextAlign.center),
      ),
    );
  }
}
