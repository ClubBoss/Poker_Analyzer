class HandData {
  String heroCards;
  List<String> streetActions;
  String position;
  Map<String, double> stacks;

  HandData({
    this.heroCards = '',
    this.position = '',
    List<String>? streetActions,
    Map<String, double>? stacks,
  })  : streetActions = streetActions ?? [],
        stacks = stacks ?? {};

  factory HandData.fromJson(Map<String, dynamic> j) => HandData(
        heroCards: j['heroCards'] as String? ?? '',
        position: j['position'] as String? ?? '',
        streetActions: List<String>.from(j['streetActions'] ?? []),
        stacks: Map<String, double>.from(j['stacks'] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'heroCards': heroCards,
        'position': position,
        if (streetActions.isNotEmpty) 'streetActions': streetActions,
        if (stacks.isNotEmpty) 'stacks': stacks,
      };
}
