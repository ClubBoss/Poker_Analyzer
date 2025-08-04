class TrainingPathNode {
  final String id;
  final String title;
  final List<String> packIds;
  final List<String> prerequisiteNodeIds;
  final String description;
  final List<String> tags;

  const TrainingPathNode({
    required this.id,
    required this.title,
    required this.packIds,
    required this.prerequisiteNodeIds,
    this.description = '',
    this.tags = const [],
  });
}
