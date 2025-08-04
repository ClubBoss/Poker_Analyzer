import '../models/training_path_node.dart';
import 'training_path_node_definition_service.dart';
import 'training_path_progress_tracker_service.dart';

/// Provides training path node recommendations based on current progress
/// and prerequisite relationships.
class NodeRecommendationService {
  final TrainingPathNodeDefinitionService definitions;
  final TrainingPathProgressTrackerService progress;

  const NodeRecommendationService({
    this.definitions = const TrainingPathNodeDefinitionService(),
    this.progress = const TrainingPathProgressTrackerService(),
  });

  /// Returns recommended nodes for [currentNode].
  ///
  /// Recommendations include:
  ///  * Prerequisite nodes for [currentNode] that haven't been completed.
  ///  * Sibling nodes sharing the same prerequisites that are unlocked and
  ///    not yet completed.
  Future<List<TrainingPathNode>> getRecommendations(
    TrainingPathNode currentNode,
  ) async {
    final completed = await progress.getCompletedNodeIds();
    final unlocked = await progress.getUnlockedNodeIds();
    final allNodes = definitions.getPath();

    final result = <TrainingPathNode>{};

    // Direct prerequisites that aren't completed yet.
    for (final prereqId in currentNode.prerequisiteNodeIds) {
      if (!completed.contains(prereqId)) {
        final node = definitions.getNode(prereqId);
        if (node != null) result.add(node);
      }
    }

    // Siblings with the same prerequisite set that are unlocked and incomplete.
    for (final node in allNodes) {
      if (node.id == currentNode.id) continue;
      if (completed.contains(node.id) || !unlocked.contains(node.id)) continue;
      if (_samePrerequisites(node, currentNode)) {
        result.add(node);
      }
    }

    return result.toList();
  }

  bool _samePrerequisites(TrainingPathNode a, TrainingPathNode b) {
    final aSet = a.prerequisiteNodeIds.toSet();
    final bSet = b.prerequisiteNodeIds.toSet();
    return aSet.length == bSet.length && aSet.containsAll(bSet);
  }
}
