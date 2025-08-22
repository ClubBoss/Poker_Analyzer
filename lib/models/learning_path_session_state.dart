/// Stores progress within an adaptive learning path graph.
class LearningPathSessionState {
  /// Identifier of the node currently in focus.
  final String currentNodeId;

  /// Mapping of branch node id to the label chosen by the user.
  final Map<String, String> branchChoices;

  /// IDs of stages marked as completed in this session.
  final Set<String> completedStageIds;

  LearningPathSessionState({
    required this.currentNodeId,
    Map<String, String>? branchChoices,
    Set<String>? completedStageIds,
  }) : branchChoices = branchChoices ?? const {},
       completedStageIds = completedStageIds ?? const {};

  /// Converts this state to a JSON map for persistence.
  Map<String, dynamic> toJson() => {
    'currentNodeId': currentNodeId,
    if (branchChoices.isNotEmpty) 'branchChoices': branchChoices,
    if (completedStageIds.isNotEmpty)
      'completedStageIds': completedStageIds.toList(),
  };

  /// Restores a [LearningPathSessionState] from [json].
  factory LearningPathSessionState.fromJson(Map<String, dynamic> json) {
    final branches = <String, String>{};
    final rawBranches = json['branchChoices'];
    if (rawBranches is Map) {
      rawBranches.forEach((key, value) {
        branches[key.toString()] = value.toString();
      });
    }

    final completed = <String>{};
    final rawCompleted = json['completedStageIds'];
    if (rawCompleted is List) {
      for (final id in rawCompleted) {
        completed.add(id.toString());
      }
    }

    return LearningPathSessionState(
      currentNodeId: json['currentNodeId']?.toString() ?? '',
      branchChoices: branches,
      completedStageIds: completed,
    );
  }
}
