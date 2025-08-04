import '../models/training_path_node.dart';
import 'training_path_node_definition_service.dart';

/// Builds a breadcrumb trail for a [TrainingPathNode] based on its
/// prerequisites.
class TrainingPathBreadcrumbService {
  final TrainingPathNodeDefinitionService definitions;

  const TrainingPathBreadcrumbService({
    this.definitions = const TrainingPathNodeDefinitionService(),
  });

  /// Returns the breadcrumb path from the root to [node], including [node].
  List<TrainingPathNode> getBreadcrumb(TrainingPathNode node) {
    final result = <TrainingPathNode>[];
    final visited = <String>{};

    void visit(TrainingPathNode current) {
      if (!visited.add(current.id)) return;
      if (current.prerequisiteNodeIds.isEmpty) {
        result.add(current);
        return;
      }
      for (final parentId in current.prerequisiteNodeIds) {
        final parent = definitions.getNode(parentId);
        if (parent != null) {
          visit(parent);
        }
      }
      result.add(current);
    }

    visit(node);
    return result;
  }
}
