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

  Map<String, dynamic> toJson() => {
    'playerCount': playerCount,
    'names': names,
    'stacks': stacks,
    'heroIndex': heroIndex,
    'pot': pot,
  };

  factory TableState.fromJson(Map<String, dynamic> json) => TableState(
    playerCount: json['playerCount'] as int? ?? 0,
    names: [for (final n in (json['names'] as List? ?? [])) n as String],
    stacks: [
      for (final s in (json['stacks'] as List? ?? [])) (s as num).toDouble(),
    ],
    heroIndex: json['heroIndex'] as int? ?? 0,
    pot: (json['pot'] as num?)?.toDouble() ?? 0.0,
  );
}
