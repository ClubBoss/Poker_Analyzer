import '../models/skill_tree.dart';

/// Utility helpers for traversing [SkillTree] graphs.
class SkillTreeGraphService {
  SkillTreeGraphService();

  /// Returns all prerequisites for [nodeId] in topological order.
  List<String> getPrerequisiteChain(SkillTree tree, String nodeId) {
    final result = <String>[];
    final visited = <String>{};

    void visit(String id) {
      final node = tree.nodes[id];
      if (node == null) return;
      for (final p in node.prerequisites) {
        if (visited.add(p)) {
          visit(p);
          result.add(p);
        }
      }
    }

    visit(nodeId);
    return result;
  }
}
