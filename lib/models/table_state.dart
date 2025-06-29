class TableState {
  final int playerCount;
  final List<String> names;
  final List<double> stacks;
  final int heroIndex;
  final double pot;

  TableState({
    required this.playerCount,
    required this.names,
    required this.stacks,
    required this.heroIndex,
    required this.pot,
  });

  TableState copy() => TableState(
        playerCount: playerCount,
        names: List<String>.from(names),
        stacks: List<double>.from(stacks),
        heroIndex: heroIndex,
        pot: pot,
      );
}
