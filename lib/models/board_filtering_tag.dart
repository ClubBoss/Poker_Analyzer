class BoardFilteringTag {
  final String id;
  final String description;
  final List<String> aliases;
  final List<String> exampleBoards;

  const BoardFilteringTag({
    required this.id,
    required this.description,
    this.aliases = const [],
    this.exampleBoards = const [],
  });
}
