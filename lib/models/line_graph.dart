class LineGraph {
  final String heroPosition;
  final List<LineStreet> streets;

  LineGraph({required this.heroPosition, required this.streets});
}

class LineStreet {
  final String street;
  final List<LineAction> actions;

  LineStreet({required this.street, required this.actions});
}

class LineAction {
  final String action;
  final String position;
  final List<LineAction> branches;

  LineAction({
    required this.action,
    required this.position,
    List<LineAction>? branches,
  }) : branches = branches ?? [];
}
