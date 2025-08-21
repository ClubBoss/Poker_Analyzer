class TheorySnippet {
  final String id;
  final String title;
  final List<String> bullets;
  final String? uri;

  const TheorySnippet({
    required this.id,
    required this.title,
    required this.bullets,
    this.uri,
  });

  const TheorySnippet.generic()
      : id = 'generic',
        title = 'Review key concepts before retrying',
        bullets = const [],
        uri = null;
}
