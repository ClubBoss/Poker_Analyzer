class InlineTheoryEntry {
  final String tag;

  /// Primary tag and optional additional tags for matching.
  ///
  /// [tags] defaults to `[tag]` when not provided.
  final List<String> tags;

  final String htmlSnippet;

  /// Optional unique identifier of the theory entry.
  final String? id;

  /// Optional human readable title.
  final String? title;

  /// Optional texture buckets this theory block is relevant for.
  final List<String> textureBuckets;

  /// Optional cluster identifiers associated with the theory block.
  final List<String> clusterIds;

  const InlineTheoryEntry({
    required this.tag,
    required this.htmlSnippet,
    List<String>? tags,
    this.id,
    this.title,
    List<String>? textureBuckets,
    List<String>? clusterIds,
  }) : tags = tags ?? const [],
       textureBuckets = textureBuckets ?? const [],
       clusterIds = clusterIds ?? const [];

  /// Returns all tags associated with this entry.
  List<String> get allTags => tags.isNotEmpty ? tags : [tag];
}
