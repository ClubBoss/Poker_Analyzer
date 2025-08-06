class InlineTheoryEntry {
  final String tag;
  final String htmlSnippet;

  /// Optional unique identifier of the theory entry.
  final String? id;

  /// Optional human readable title.
  final String? title;

  const InlineTheoryEntry({
    required this.tag,
    required this.htmlSnippet,
    this.id,
    this.title,
  });
}
