class SkillTreeDependencyLink {
  final String nodeId;
  final List<String> prerequisites;
  final String hint;

  const SkillTreeDependencyLink({
    required this.nodeId,
    required this.prerequisites,
    required this.hint,
  });
}
