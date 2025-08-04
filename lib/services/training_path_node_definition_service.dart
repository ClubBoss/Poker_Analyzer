import 'package:collection/collection.dart';

import '../models/training_path_node.dart';

class TrainingPathNodeDefinitionService {
  static const List<TrainingPathNode> _nodes = [
    TrainingPathNode(
      id: 'starter_pushfold_10bb',
      title: 'Starter Push/Fold 10bb',
      packIds: ['starter_pushfold_10bb'],
      prerequisiteNodeIds: [],
    ),
    TrainingPathNode(
      id: 'starter_postflop_basics',
      title: 'Starter Postflop Basics',
      packIds: ['starter_postflop_basics'],
      prerequisiteNodeIds: ['starter_pushfold_10bb'],
    ),
    TrainingPathNode(
      id: 'advanced_pushfold_15bb',
      title: 'Advanced Push/Fold 15bb',
      packIds: ['advanced_pushfold_15bb'],
      prerequisiteNodeIds: ['starter_postflop_basics'],
    ),
  ];

  const TrainingPathNodeDefinitionService();

  List<TrainingPathNode> getPath() => _nodes;

  TrainingPathNode? getNode(String id) =>
      _nodes.firstWhereOrNull((node) => node.id == id);
}
