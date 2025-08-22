import '../models/skill_tree_node_model.dart';
import '../models/skill_tree.dart';
import '../models/skill_tree_build_result.dart';

/// Builds a directed skill tree graph from a list of nodes with prerequisites.
class SkillTreeBuilderService {
  SkillTreeBuilderService();

  /// Constructs a [SkillTree] from [nodes].
  /// Optionally filters by [category].
  SkillTreeBuildResult build(
    List<SkillTreeNodeModel> nodes, {
    String? category,
  }) {
    final filtered = category == null
        ? nodes
        : [
            for (final n in nodes)
              if (n.category == category) n,
          ];

    final map = {for (final n in filtered) n.id: n};
    final children = <String, List<String>>{for (final n in filtered) n.id: []};
    final inDegree = <String, int>{for (final n in filtered) n.id: 0};

    for (final n in filtered) {
      for (final p in n.prerequisites) {
        if (map.containsKey(p)) {
          children[p]!.add(n.id);
          inDegree[n.id] = inDegree[n.id]! + 1;
        }
      }
    }

    final ancestors = <String, List<String>>{
      for (final n in filtered) n.id: [],
    };
    for (final n in filtered) {
      final visited = <String>{};
      final stack = <String>[n.id];
      while (stack.isNotEmpty) {
        final cur = stack.removeLast();
        for (final p in map[cur]?.prerequisites ?? []) {
          if (visited.add(p)) {
            ancestors[n.id]!.add(p);
            stack.add(p);
          }
        }
      }
    }

    // Detect cycles using Kahn's algorithm.
    final q = <String>[
      for (final e in inDegree.entries)
        if (e.value == 0) e.key,
    ];
    final localDeg = Map<String, int>.from(inDegree);
    var visitedCount = 0;
    while (q.isNotEmpty) {
      final id = q.removeLast();
      visitedCount++;
      for (final c in children[id] ?? []) {
        final d = localDeg[c]! - 1;
        localDeg[c] = d;
        if (d == 0) q.add(c);
      }
    }
    final warnings = <String>[];
    if (visitedCount != filtered.length) {
      warnings.add('circular_dependency');
    }

    final tree = SkillTree(
      nodes: map,
      children: children,
      ancestors: ancestors,
    );
    return SkillTreeBuildResult(tree: tree, warnings: warnings);
  }
}
