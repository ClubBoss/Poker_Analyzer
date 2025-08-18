import 'package:flutter/material.dart';

import '../models/mini_map_graph.dart';
import '../models/mini_map_node.dart';
import '../models/player_profile.dart';
import '../services/cluster_node_navigator.dart';
import '../services/mini_lesson_library_service.dart';
import '../models/theory_mini_lesson_node.dart';
import 'theory_cluster_completion_overlay.dart';

/// Simple overlay showing a cluster mini map.
class TheoryClusterMapOverlay extends StatelessWidget {
  final MiniMapGraph graph;
  final PlayerProfile profile;
  final List<TheoryMiniLessonNode> lessons;
  final ValueChanged<MiniMapNode>? onTap;
  final Set<String> tagsFilter;

  const TheoryClusterMapOverlay({
    super.key,
    required this.graph,
    required this.profile,
    required this.lessons,
    this.onTap,
    this.tagsFilter = const {},
  });

  bool _lessonMatchesTags(String id, Set<String> tags) {
    final lesson = MiniLessonLibraryService.instance.getById(id);
    if (lesson == null) return false;
    final lessonTags = lesson.tags.map((e) => e.trim().toLowerCase());
    return tags.every((t) => lessonTags.contains(t.toLowerCase()));
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final n in graph.nodes)
                  if (tagsFilter.isEmpty ||
                      _lessonMatchesTags(n.id, tagsFilter))
                    GestureDetector(
                      onTap: () async {
                        if (onTap != null) onTap!(n);
                        final lesson = MiniLessonLibraryService.instance
                            .getById(n.id);
                        if (lesson != null) {
                          await ClusterNodeNavigator.handleTap(
                            context,
                            lesson,
                            profile,
                          );
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
          Positioned(
            right: 0,
            top: 0,
            child: TheoryClusterCompletionOverlay(lessons: lessons, size: 24),
          ),
        ],
      ),
    );
  }
}
