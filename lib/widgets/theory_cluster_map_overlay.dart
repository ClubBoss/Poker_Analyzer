import 'package:flutter/material.dart';

import '../models/mini_map_graph.dart';
import '../models/mini_map_node.dart';
import '../models/player_profile.dart';
import '../services/cluster_node_navigator.dart';
import '../services/mini_lesson_library_service.dart';
import '../models/theory_mini_lesson_node.dart';

/// Simple overlay showing a cluster mini map.
class TheoryClusterMapOverlay extends StatelessWidget {
  final MiniMapGraph graph;
  final PlayerProfile profile;
  final ValueChanged<MiniMapNode>? onTap;

  const TheoryClusterMapOverlay({
    super.key,
    required this.graph,
    required this.profile,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final n in graph.nodes)
              GestureDetector(
                onTap: () async {
                  if (onTap != null) onTap!(n);
                  final lesson = MiniLessonLibraryService.instance.getById(n.id);
                  if (lesson != null) {
                    await ClusterNodeNavigator.handleTap(context, lesson, profile);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: n.isCurrent
                        ? Colors.orangeAccent
                        : Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    n.title,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
