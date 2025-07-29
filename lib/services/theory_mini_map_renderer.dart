import '../models/mini_map_edge.dart';
import '../models/mini_map_graph.dart';
import '../models/mini_map_node.dart';
import '../models/theory_lesson_cluster.dart';
import '../models/theory_mini_lesson_node.dart';

/// Generates a graph representation of a theory lesson cluster
/// suitable for rendering a minimap.
class TheoryMiniMapRenderer {
  final TheoryLessonCluster cluster;
  final Map<String, TheoryMiniLessonNode> _byId = {};

  TheoryMiniMapRenderer(this.cluster) {
    for (final l in cluster.lessons) {
      _byId[l.id] = l;
    }
  }

  /// Builds a [MiniMapGraph] marking [currentLessonId] as the active node.
  MiniMapGraph build(String currentLessonId) {
    final nodes = <MiniMapNode>[];
    final edges = <MiniMapEdge>[];
    for (final l in cluster.lessons) {
      nodes.add(
        MiniMapNode(
          id: l.id,
          title: l.title,
          isCurrent: l.id == currentLessonId,
        ),
      );
      for (final next in l.nextIds) {
        if (_byId.containsKey(next)) {
          edges.add(MiniMapEdge(fromId: l.id, toId: next));
        }
      }
    }
    return MiniMapGraph(nodes: nodes, edges: edges);
  }
}
