import 'skill_tree.dart';

class SkillTreeBuildResult {
  final SkillTree tree;
  final List<String> warnings;

  const SkillTreeBuildResult({required this.tree, this.warnings = const []});
}
