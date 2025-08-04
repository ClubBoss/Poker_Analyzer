class TrainingPathNode {
  final String id;
  final String title;
  final List<String> packIds;
  final List<String> prerequisiteNodeIds;

  const TrainingPathNode({
    required this.id,
    required this.title,
    required this.packIds,
    required this.prerequisiteNodeIds,
  });
}
