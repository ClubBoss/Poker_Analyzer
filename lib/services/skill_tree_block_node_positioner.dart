import 'dart:math' as math;
import 'package:flutter/widgets.dart';

import '../models/skill_tree_node_model.dart';

/// Computes the rectangle positions of nodes inside a level block.
class SkillTreeBlockNodePositioner {
  SkillTreeBlockNodePositioner();

  /// Returns a map of node id to rectangle in the block coordinate space.
  Map<String, Rect> calculate({
    required List<SkillTreeNodeModel> nodes,
    double nodeWidth = 120,
    double nodeHeight = 80,
    double spacing = 16,
    TextDirection direction = TextDirection.ltr,
    bool center = false,
  }) {
    final rects = <String, Rect>{};
    if (nodes.isEmpty) return rects;

    final totalWidth =
        nodes.length * nodeWidth + math.max(0, nodes.length - 1) * spacing;
    var x = center ? -totalWidth / 2 : 0.0;
    final ordered = direction == TextDirection.ltr
        ? nodes
        : nodes.reversed.toList();

    for (final node in ordered) {
      rects[node.id] = Rect.fromLTWH(x, 0, nodeWidth, nodeHeight);
      x += nodeWidth + spacing;
    }

    return rects;
  }
}
