import '../models/training_path_node.dart';
import 'training_path_node_definition_service.dart';
import 'training_path_progress_tracker_service.dart';

/// Represents a recommendation for a training path node along with a reason why
/// it is suggested.
class NodeRecommendation {
  final TrainingPathNode node;
  final String reason;

  NodeRecommendation({required this.node, required this.reason});
}

/// Provides training path node recommendations based on current progress
/// and prerequisite relationships.
class NodeRecommendationService {
  final TrainingPathNodeDefinitionService definitions;
  final TrainingPathProgressTrackerService progress;

  NodeRecommendationService({
    this.definitions = const TrainingPathNodeDefinitionService(),
    this.progress = const TrainingPathProgressTrackerService(),
  });

  /// Returns recommended nodes for [currentNode].
  ///
  /// Recommendations include:
  ///  * Prerequisite nodes for [currentNode] that haven't been completed.
  ///  * Sibling nodes sharing the same prerequisites that are unlocked and
  ///    not yet completed.
  Future<List<NodeRecommendation>> getRecommendations(
    TrainingPathNode currentNode,
  ) async {
    final completed = await progress.getCompletedNodeIds();
    final unlocked = await progress.getUnlockedNodeIds();
    final allNodes = definitions.getPath();

    final recommendations = <NodeRecommendation>[];
    final seenIds = <String>{};

    // Direct prerequisites that aren't completed yet.
    for (final prereqId in currentNode.prerequisiteNodeIds) {
      if (!completed.contains(prereqId)) {
        final node = definitions.getNode(prereqId);
        if (node != null && seenIds.add(node.id)) {
          recommendations.add(
            NodeRecommendation(node: node, reason: 'unmet prerequisite'),
          );
        }
      }
    }

    // Siblings with the same prerequisite set that are unlocked and incomplete.
    for (final node in allNodes) {
      if (node.id == currentNode.id) continue;
      if (completed.contains(node.id) || !unlocked.contains(node.id)) continue;
      if (_samePrerequisites(node, currentNode) && seenIds.add(node.id)) {
        recommendations.add(
          NodeRecommendation(node: node, reason: 'parallel topic'),
        );
      }
    }

    return recommendations;
  }

  bool _samePrerequisites(TrainingPathNode a, TrainingPathNode b) {
    final aSet = a.prerequisiteNodeIds.toSet();
    final bSet = b.prerequisiteNodeIds.toSet();
    return aSet.length == bSet.length && aSet.containsAll(bSet);
  }
}
