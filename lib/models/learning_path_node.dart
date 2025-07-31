/// Base class for nodes in a learning path graph.
abstract class LearningPathNode {
  /// Unique identifier of this node.
  String get id;

  /// Whether the node has been recovered from a mistake via boosters.
  bool get recoveredFromMistake;
}
