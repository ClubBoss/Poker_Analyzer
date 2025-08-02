class TheoryBlockModel {
  final String id;
  final String title;
  final List<String> nodeIds;
  final List<String> practicePackIds;
  final List<String> tags;

  const TheoryBlockModel({
    required this.id,
    required this.title,
    required this.nodeIds,
    required this.practicePackIds,
    List<String>? tags,
  }) : tags = tags ?? const [];

  factory TheoryBlockModel.fromYaml(Map yaml) {
    final nodeYaml = yaml['nodeIds'];
    final nodes = <String>[];
    if (nodeYaml is List) {
      for (final n in nodeYaml) {
        nodes.add(n.toString());
      }
    }
    final packYaml = yaml['practicePackIds'];
    final packs = <String>[];
    if (packYaml is List) {
      for (final p in packYaml) {
        packs.add(p.toString());
      }
    }
    final tagYaml = yaml['tags'];
    final tags = <String>[];
    if (tagYaml is List) {
      for (final t in tagYaml) {
        tags.add(t.toString());
      }
    }
    return TheoryBlockModel(
      id: yaml['id']?.toString() ?? '',
      title: yaml['title']?.toString() ?? '',
      nodeIds: nodes,
      practicePackIds: packs,
      tags: tags,
    );
  }
}
