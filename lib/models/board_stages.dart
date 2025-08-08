class BoardStages {
  final List<String> flop;
  final String turn;
  final String river;
  final Set<String> textureTags;

  const BoardStages({
    required this.flop,
    required this.turn,
    required this.river,
    this.textureTags = const {},
  });
}
