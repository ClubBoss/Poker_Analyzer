import 'learning_path_node.dart';

/// A branching decision in a learning path.
class LearningBranchNode implements LearningPathNode {
  @override
  final String id;

  @override
  final bool recoveredFromMistake;

  /// Question shown to the user when choosing a branch.
  final String prompt;

  /// Maps branch labels to target node ids.
  final Map<String, String> branches;

  const LearningBranchNode({
    required this.id,
    required this.prompt,
    Map<String, String>? branches,
    this.recoveredFromMistake = false,
  }) : branches = branches ?? const {};

  /// Returns the target node id for [choice] or `null` if not found.
  String? targetFor(String choice) => branches[choice];

  factory LearningBranchNode.fromJson(Map<String, dynamic> json) {
    final map = <String, String>{};
    final rawBranches = json['branches'];
    if (rawBranches is Map) {
      rawBranches.forEach((k, v) {
        map[k.toString()] = v.toString();
      });
    }
    return LearningBranchNode(
      id: json['id']?.toString() ?? '',
      prompt: json['prompt']?.toString() ?? '',
      branches: map,
      recoveredFromMistake: json['recoveredFromMistake'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'prompt': prompt,
    if (branches.isNotEmpty) 'branches': branches,
    if (recoveredFromMistake) 'recoveredFromMistake': true,
  };

  factory LearningBranchNode.fromYaml(Map yaml) {
    final map = <String, dynamic>{};
    yaml.forEach((k, v) => map[k.toString()] = v);
    return LearningBranchNode.fromJson(map);
  }
}
