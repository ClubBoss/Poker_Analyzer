import "skill_tree_node_model.dart";

class SkillTree {
  final Map<String, SkillTreeNodeModel> nodes;
  final Map<String, List<String>> _children;
  final Map<String, List<String>> _ancestors;

  SkillTree({
    required this.nodes,
    Map<String, List<String>>? children,
    Map<String, List<String>>? ancestors,
  }) : _children = children ?? const {},
       _ancestors = ancestors ?? const {};

  List<SkillTreeNodeModel> get roots => [
    for (final n in nodes.values)
      if (n.prerequisites.isEmpty) n,
  ];

  List<SkillTreeNodeModel> childrenOf(String id) => [
    for (final c in _children[id] ?? <String>[]) nodes[c]!,
  ];

  List<SkillTreeNodeModel> ancestorsOf(String id) => [
    for (final a in _ancestors[id] ?? <String>[]) nodes[a]!,
  ];
}
