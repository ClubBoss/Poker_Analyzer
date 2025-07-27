class TheoryTrack {
  final String id;
  final String title;
  final List<String> blockIds;

  const TheoryTrack({
    required this.id,
    required this.title,
    required this.blockIds,
  });

  factory TheoryTrack.fromYaml(Map yaml) {
    final list = yaml['blocks'];
    final blocks = <String>[];
    if (list is List) {
      for (final v in list) {
        blocks.add(v.toString());
      }
    }
    return TheoryTrack(
      id: yaml['id']?.toString() ?? '',
      title: yaml['title']?.toString() ?? '',
      blockIds: blocks,
    );
  }
}
